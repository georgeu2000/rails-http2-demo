DRAFT = 'h2'.freeze

def respond req, buffer, stream, sock
  ap __method__

  env = build_env_for( req, buffer, stream, sock )
  status, headers, body_arr =  app.call( env )
  body = body_arr.join

  headers.merge( status:status )
    
  # send_push stream, 200, 'This is the push message.'

  content_length = { 'content-length' => body.bytesize.to_s }
  headers.merge!( content_length )

  ap headers
  ap body

  stream.headers headers, end_stream: false
  stream.data    body
end

def app
  Rails.application.initialize!
end

def send_push stream, status, body
  headers = { 'status' => status.to_s,
              'content-length' => body.bytesize.to_s }

  push_stream =  nil
  stream.promise( headers ) do | push |
    push.headers headers
    push_stream = push
  end

  push_stream.data body
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