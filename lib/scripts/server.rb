require_relative 'helper'

def start_server options
  puts "Starting #{ options[ :secure ] ? 'secure' : 'insecure' } server on port #{options[:port]}"
  server = TCPServer.new(options[:port])

  if options[:secure]
    server = secure_server( server )
  end

  loop do
    sock = server.accept
    puts 'New TCP connection.'

    thr = Thread.new do
      handle_connection_for sock
    end
  end
end