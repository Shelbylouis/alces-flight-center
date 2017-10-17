Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  get '/reset-password' => 'clearance/passwords#new', as: 'passwords'
  post '/reset-password' => 'clearance/passwords#create'
  resources :users, controller: 'clearance/users' do
    resource :password,
      controller: 'clearance/passwords',
      only: [:edit, :update]
  end

  constraints Clearance::Constraints::SignedIn.new { |user| user.admin? } do
    root 'rails_admin/main#dashboard'

    # To display a working link to sign users out of the admin dashboard,
    # rails-admin expects a `logout_path` route helper to exist which will sign
    # them out; this declaration defines this.
    delete :logout, to: 'clearance/sessions#destroy'
  end

  constraints Clearance::Constraints::SignedIn.new do
    root 'home#index'
    delete '/sign_out' => 'clearance/sessions#destroy', as: 'sign_out'

    resources :cases, only: [:new, :index, :create] do
      member do
        post :archive
      end
    end

    resources :clusters, only: :show
    resources :components, only: :show
  end

  constraints Clearance::Constraints::SignedOut.new do
    root 'clearance/sessions#new', as: 'sign_in'
    post '/' => 'clearance/sessions#create', as: 'session'
  end
end
