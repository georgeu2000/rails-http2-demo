Rails.application.routes.draw do
  root to: 'pages#index'

  get '/push', to:'pages#push'
end
