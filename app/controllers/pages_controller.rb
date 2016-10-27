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
end