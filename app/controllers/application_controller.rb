class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :log_request
  before_action :set_stream

  def log_request
    puts "path: #{ request.path }".green
  end

  def set_stream
    @stream = request.env[ 'STREAM' ]
  end
end
