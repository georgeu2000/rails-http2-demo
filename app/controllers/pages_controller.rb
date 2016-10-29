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
    @headers = all_headers.join( '<br>' )
    @params  = all_params.join( '<br>'  )
  end


  private

  def all_headers
    request.headers.select{ | k, v |  k.match /^HTTP_/        }
                   .map{    | k, v | "#{ k.gsub( /^HTTP_/, '' ).capitalize }: #{ v }" }
  end

  def all_params
    request.query_parameters.map{| k,v | "#{ k }: #{ v }" }
  end
end