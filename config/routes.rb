Dradis::Plugins::CSV::Engine.routes.draw do
  resources :projects, only: [] do
    resources :upload, only: [:new], path: '/csv/upload'
  end
end
