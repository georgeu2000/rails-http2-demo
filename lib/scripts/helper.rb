DRAFT = 'h2'.freeze

def respond req, buffer, stream, sock
  ap ENV[ "RAILS_ENV" ]
  if req[ ':path' ] == '/'
    send_push stream, 200, File.read( 'app/assets/stylesheets/main.css' )
  end
  
  env = build_env_for( req, buffer, stream, sock )
  status, headers, body_arr =  app.call( env )
  
  delete_problem_headers! headers

  headers.merge!( ':status'      => status.to_s  )
  headers.merge!( 'content-type' => 'text/html' )

  body = ''
  body_arr.each do | part |
    body << part
  end
  
  stream.headers headers, end_stream: false
  stream.data    body,    end_stream: true
end

def send_push stream, status, body
  promise_headers = { ':method'    =>  'GET',
                      ':path'      => '/assets/main.css',
                      ':authority' => 'localhost:8080',
                      ':scheme'    => 'https',
                      'cache-control' => 'public, max-age=31536000' }

  push_stream =  nil
  stream.promise( promise_headers ) do | push |
    headers = { ':status' => '200', 'content-type' => 'text/css' }
    
    push.headers headers
    push_stream = push
  end

  push_stream.data body
end

def delete_problem_headers! headers
  headers.delete 'ETag'
  headers.delete "X-Frame-Options"
  headers.delete "X-XSS-Protection"
  headers.delete "X-Content-Type-Options"
  headers.delete "Cache-Control"
  headers.delete "X-Request-Id"
  headers.delete "X-Runtime"
  headers.delete "Content-Length"
  headers.delete "Content-Type"
  headers.delete "Last-Modified"
end

def app
  begin
    Rails.application.initialize!
  rescue
  end

  Rails.logger ||= Logger.new(STDOUT)
  Rails.application
end

def build_env_for req, body, stream, sock
  uri = "#{ req[ ':scheme' ]}://#{ req[ ':authority' ]}#{ req[ ':path' ]}"

  rack_req = Rack::MockRequest.env_for( uri )
  rack_req[ 'ACCEPT' ] = req[ 'accept' ]
  rack_req[ 'SOCKET' ] = sock

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