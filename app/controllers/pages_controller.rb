class PagesController < ApplicationController
  def index
    # sleep 2
  end

  def push
    headers = { method: :GET,
                path:   '/assets/main.css',
                'Content-Type' => 'text/css' }
    file = File.read( 'app/assets/stylesheets/main.css' )

    send_push @stream, 200, headers, file
  end

  def mirror
    @method  = request.method
    @headers = all_headers.join( '<br>' )
    @params  = all_params.join( '<br>'  )
    @body    = request.body.read
  end


  private

  def all_headers
    request.headers.map do | k, v |
                      key = k.gsub( /^HTTP_/, '' ).split( '_'        )
                                                  .map( &:capitalize )
                                                  .join( '-'         )
                      "#{ key }: #{ v }"
                    end
  end

  def all_params
    request.query_parameters.map{| k,v | "#{ k }: #{ v }" }
  end
end