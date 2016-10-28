require_relative 'helper'

def start_server options
  begin
    puts "Starting #{ options[ :secure ] ? 'secure' : 'insecure' } server on port #{options[:port]}"
    server = TCPServer.new(options[:port])

    if options[:secure]
      server = secure_server( server )
    end
  rescue
    puts "Could not start server"
    exit
  end

  loop do
    sock = server.accept
    puts 'New TCP connection.'

    Thread.new do
      handle_connection_for sock
    end
  end
end