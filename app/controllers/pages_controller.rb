class PagesController < ApplicationController
  def index
    render html: 'Welcome to your life'
  end
end