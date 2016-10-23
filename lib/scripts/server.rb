require_relative 'helper'

def start_server options
  puts "Starting server on port #{options[:port]}"
  server = TCPServer.new(options[:port])

  if options[:secure]
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

    server = OpenSSL::SSL::SSLServer.new(server, ctx)
  end

  loop do
    sock = server.accept
    puts 'New TCP connection!'

    conn = HTTP2::Server.new
    conn.on(:frame) do |bytes|
      puts "Writing bytes: #{bytes.unpack("H*").first}"
      sock.write bytes
    end
    conn.on(:frame_sent) do |frame|
      puts "Sent frame: #{frame.inspect}"
    end
    conn.on(:frame_received) do |frame|
      puts "Received frame: #{frame.inspect}"
    end

    conn.on(:stream) do |stream|
      log = Logger.new(STDOUT)
      req, buffer = {}, ''

      stream.on(:active) { log.info 'client opened new stream' }
      stream.on(:close)  { log.info 'stream closed' }

      stream.on(:headers) do |h|
        req = Hash[*h.flatten]
        log.info "request headers: #{h}"
      end

      stream.on(:data) do |d|
        log.info "payload chunk: <<#{d}>>"
        buffer << d
      end

      stream.on(:half_close) do
        log.info 'client closed its end of the stream'

        # respond req, buffer, stream, sock

        response = 'Welcome fake request'
        stream.headers({
          ':status' => '200',
          'content-length' => response.bytesize.to_s,
          'content-type' => 'text/plain',
        }, end_stream: false)  

        stream.data(response)
      end
    end

    while !sock.closed? && !(sock.eof? rescue true) # rubocop:disable Style/RescueModifier
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
end