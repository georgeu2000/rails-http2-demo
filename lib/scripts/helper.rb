DRAFT = 'h2'.freeze


def respond app, req, buffer, stream
  env = build_env_for( req, buffer, stream )
  status, headers, body_arr =  app.call( env )
  body = body_arr.join

  headers.merge( status:status )
  ap headers
  
  send_push stream, 200, 'This is the push message.'

  content_length = { 'content-length' => body.bytesize.to_s }
  headers.merge!( content_length )

  stream.headers headers, end_stream: false
  stream.data    body
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

def build_env_for req, body, stream
  env = req.map do | k,v |
    key = k.gsub( /^:/, '' ).to_sym

    [ key, v ]
  end.to_h

  uri = "#{ env[ :scheme ]}://#{ env[ :authority ]}#{ env[ :path ]}"

  ap rack_req = Rack::MockRequest.env_for( uri, env )

  rack_req
end

def upgrade_message
<<-eos 
HTTP/1.1 101 Switching Protocols 
Connection: Upgrade
Upgrade: h2c

eos
end

def no_upgrade_message
  "HTTP-Version = HTTP/1.1
status: 200
content-type: text/plain
content-length: 19
Date: Thu Oct 13 03:38:00 2016

Staying at HTTP 1.1\n"
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