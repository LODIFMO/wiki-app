Rails.application.routes.draw do
  get 'pages/show'

  root 'pages#index'

  namespace :api do
    get 'pages/graph' => 'pages#graph', format: /json/
    get 'pages/dgraph' => 'pages#data_graph', format: /json/

    # ping redis
    get 'pages/redis/ping' => 'pages#redis_ping', format: /json/

    # get data
    get 'projects' => 'pages#projects', format: /json/
  end
end
