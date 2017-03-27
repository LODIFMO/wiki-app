Rails.application.routes.draw do
  get 'pages/show'
  get 'pages/keyword' => 'pages#keyword', format: /json/
  root 'pages#index'
end
