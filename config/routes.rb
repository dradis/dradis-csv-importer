Dradis::Plugins::CSV::Engine.routes.draw do
  resources :projects, only: [] do
    resources :upload, only: [:new, :create], path: '/csv/upload'
  end
end
