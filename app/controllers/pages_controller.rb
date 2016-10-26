class PagesController < ApplicationController
  def index
    headers = { ':method'    =>  'GET',
                ':path'      => '/assets/main.css',
                ':authority' => 'localhost:8080',
                ':scheme'    => 'https',
                'cache-control' => 'public, max-age=31536000' }

    send_push @stream, 200, headers, File.read( 'app/assets/stylesheets/main.css' )
  end
end