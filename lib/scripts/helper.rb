DRAFT = 'h2'.freeze

def respond req, buffer, stream
  env = build_env_for( req, buffer, stream )
  status, headers, body_arr =  app.call( env )

  new_headers = headers_for( headers, status )
  
  body = ''
  body_arr.each do | part |
    body << part
  end

  stream.headers new_headers, end_stream: false
  stream.data    body,        end_stream: true
end

def send_push stream, status, headers, body
  push_stream =  nil
  stream.promise( headers ) do | push |
    headers = { ':status' => '200', 'content-type' => 'text/css' }
    
    push.headers headers
    push_stream = push
  end

  push_stream.data body
end

def headers_for headers, status
  new_headers = { ':status' => status.to_s }
  headers.each do | k,v |
    new_headers[ k.downcase ] = v
  end

  new_headers
end

def app
  begin
    Rails.application.initialize!
  rescue
  end

  Rails.logger ||= Logger.new(STDOUT)
  Rails.application
end

def build_env_for req, body, stream
  uri = "#{ req[ ':scheme' ]}://#{ req[ ':authority' ]}#{ req[ ':path' ]}"

  rack_req = Rack::MockRequest.env_for( uri )
  rack_req[ 'ACCEPT' ] = req[ 'accept' ]
  rack_req[ 'STREAM' ] = stream

  rack_req
end

def print_frame frame
  payload = frame[ :payload ]
  print "stream #{ frame[ :stream ]}: frame #{ frame[ :type ].upcase }"

  if payload.nil?
    puts '. <no payload>'
    return
  end

  if payload.is_a?( Array ) && payload.empty?
    puts '. <no payload>'
    return
  end
  
  if payload.is_a? Array
    puts ':'
    puts payload.map{ | k,v | "  #{ k }: #{ v }" }
    
    return
  end

  if payload.ascii_only?
    puts ':'
    puts payload

    return
  end

  puts ':'
  puts to_hex payload
end

def to_hex str
  str.chars.map{| c | "#{ c.unpack( 'H*' ).first.upcase }"}.join( ' ' )
end

def handle_connection_for sock
  conn = HTTP2::Server.new
  conn.on(:frame) do |bytes|
    # puts "Writing bytes: #{bytes.unpack("H*").first}"
    sock.write bytes
  end
  conn.on(:frame_sent) do |frame|
    # puts "Sent frame: #{frame.inspect}"
  end
  conn.on(:frame_received) do |frame|
    if frame[ :error ].present? && frame[ :error ] != :no_error
      puts "Received error frame:".yellow
      ap frame
    end
  end

  conn.on(:stream) do |stream|
    handle_stream_for stream
  end

  while !sock.closed? && !(sock.eof? rescue true)
    data = sock.readpartial(1024)
    # puts "Received bytes: #{data.unpack("H*").first}"

    begin
      conn << data
    rescue => e
      puts "#{e.class} exception: #{e.message} - closing socket."
      e.backtrace.each { |l| puts "\t" + l }
      sock.close
    end
  end
end

def handle_stream_for stream
  log = Logger.new(STDOUT)
  req, buffer = {}, ''

  stream.on(:active) { log.info 'client opened new stream' }
  stream.on(:close)  { log.info 'stream closed' }

  stream.on(:headers) do |h|
    req = Hash[*h.flatten]
    # log.info "request headers: #{h}"
  end

  stream.on(:data) do |d|
    log.info "payload chunk: <<#{d}>>"
    buffer << d
  end

  stream.on(:half_close) do
    log.info 'client closed its end of the stream'
    
    respond req, buffer, stream
  end
end

def secure_server server
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.cert = OpenSSL::X509::Certificate.new(File.open('lib/keys/localhost-cert.pem'))
  ctx.key = OpenSSL::PKey::RSA.new(File.open('lib/keys/localhost-key.pem'))

  ctx.ssl_version = :TLSv1_2
  ctx.alpn_protocols = ['h2']

  ctx.alpn_select_cb = lambda do |protocols|
    raise "Protocol #{DRAFT} is required" if protocols.index(DRAFT).nil?
    DRAFT
  end

  ctx.tmp_ecdh_callback = lambda do |*_args|
    OpenSSL::PKey::EC.new 'prime256v1'
  end

  OpenSSL::SSL::SSLServer.new(server, ctx)
end