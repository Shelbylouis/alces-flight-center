Rails.application.routes.draw do
  get 'welcome/index'

  resources :sites do
    resources :contacts
    resources :clusters
  end

  resources :clusters do
    resources :components
  end

  root 'welcome#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
