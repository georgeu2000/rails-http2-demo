class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_filter :log_request

  def log_request
    puts "path: #{ request.path }".green
  end
end
