require_relative 'helper'

DRAFT = 'h2'.freeze

def start_server
  puts "\n\nStarting server."
  app = Rails.application.initialize!

  server = TCPServer.new( 8080 )


  # Secure server
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.cert = OpenSSL::X509::Certificate.new(File.open('lib/keys/server.crt'))
  ctx.key = OpenSSL::PKey::RSA.new(File.open('lib/keys/server.key'))

  ctx.ssl_version = :SSLv23
  ctx.options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options]
  ctx.ciphers = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers]

  ctx.alpn_select_cb = lambda do |protocols|
    raise "Protocol #{DRAFT} is required" if protocols.index(DRAFT).nil?
    DRAFT
  end
  server = OpenSSL::SSL::SSLServer.new(server, ctx)
  # --------------

  loop do
    sock = server.accept
    puts "New server connection on #{ sock }"

    conn = HTTP2::Server.new
    conn.on(:frame) do |bytes|
      # print "Writing bytes: "
      # print_as_hex bytes

      sock.write bytes
    end

    conn.on(:frame_sent) do |frame|
      print "\nSent frame: "
      # print_frame frame
    end

    conn.on(:frame_received) do |frame|
      print "\nReceived frame: "
      print_frame frame
    end

    conn.on(:stream) do |stream|
      puts "Started stream #{ stream.id } with weight #{ stream.weight }"
      req, buffer = {}, ''

      stream.on(:active) { puts 'client opened new stream' }
      stream.on(:close)  { puts 'stream closed' }

      stream.on(:headers) do |h|
        req = Hash[ *h.flatten ]
        puts "request headers: #{ h.join ' ' }"
      end

      stream.on(:data) do |d|
        puts "payload chunk: <<#{ d.ai }>>"
        buffer << d
      end

      stream.on(:half_close) do
        respond app, req, buffer, stream
        buffer = ''
      end
    end

    while !sock.closed? && !(sock.eof? rescue true)
      data = sock.readpartial(1024)
      puts "Received bytes: #{data.unpack("H*").first}"

      begin
        conn << data

      rescue => e
        puts "\n#{ e.class }: #{e.message} - closing socket.".redish
        e.backtrace # .reject{| l | l.match /gems/ }
                   .each { |l| puts "  " + l.purpleish }
        
        sock.close
      end
    end

    trap 'SIGINT' do
      puts 'Stopping server.'
      exit
    end
  end
end