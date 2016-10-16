require 'uri'
require 'socket'
require 'openssl'
require 'http/2'

require_relative './helper'


class Client
  def run
    puts ''

    @uri = URI.parse( ARGV[ 0 ])
    tcp = TCPSocket.new(uri.host, uri.port)
    @sock = nil

    if uri.scheme == 'https'
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE

      ctx.npn_protocols = [DRAFT]
      ctx.npn_select_cb = lambda do |protocols|
        puts "NPN protocols supported by server: #{protocols}"
        DRAFT if protocols.include? DRAFT
      end

      @sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
      @sock.sync_close = true
      @sock.hostname = uri.hostname
      @sock.connect
    else
      @sock = tcp
    end
    
    init_conn

    1.times do
      make_request_for :GET
    end

    listen
  end


  private

  def log message
    puts message
  end

  def make_request_for method
    puts "\nSending HTTP 2.0 #{ method } request."
    puts uri

    stream = conn.new_stream
    stream.reprioritize( weight: 200 )
    
    head = {
      ':scheme' => uri.scheme,
      ':method' => method.to_s,
      ':authority' => [ uri.host, uri.port ].join( ':' ),
      ':path' => uri.path,
      'accept' => '*/*',
    }

    if method == :GET
      stream.headers head, end_stream: true
    else
      stream.headers head, end_stream: false
      stream.data 'message from client'
    end
  end

  def uri
    @uri
  end

  def conn
    @conn
  end

  def sock
    @sock
  end

  def init_conn
    @conn = HTTP2::Client.new

    conn.on(:frame) do |bytes|
      # puts "Sending bytes: #{bytes.unpack("H*").first}"
      sock.print bytes
      sock.flush
    end

    conn.on(:frame_sent) do |frame|
      print "\nSent frame: "
      print_frame frame
    end

    conn.on(:frame_received) do |frame|
      print "\nReceived frame: "
      print_frame frame
      # puts "\nReceived frame: #{frame.ai}"
    end

    conn.on(:promise) do |promise|
      promise.on(:headers) do |h|
        puts "\nReceived promise headers: #{ h }"
      end

      promise.on(:data) do |d|
        puts "\nReceived promise data: #{ d }"
      end
    end

    conn.on(:altsvc) do |f|
      log "received ALTSVC #{f}"
    end
  end

  def init_listeners_for stream
    stream.on(:close) do
      log 'stream closed'
      # sock.close
    end

    stream.on(:half_close) do
      log 'closing client-end of the stream'
    end

    stream.on(:headers) do |h|
      log "response headers: #{h.ai }"
    end

    stream.on(:data) do |d|
      log "response data chunk: <<#{d}>>"
    end

    stream.on(:altsvc) do |f|
      log "received ALTSVC #{f}"
    end
  end

  def listen
    while !sock.closed? && !sock.eof?
      data = sock.read_nonblock(1024)
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

client = Client.new.run
