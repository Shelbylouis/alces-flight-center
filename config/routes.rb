Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  resources :passwords, controller: "clearance/passwords", only: [:create, :new]
  resource :session, controller: "clearance/sessions", only: [:create]

  resources :users, controller: "clearance/users", only: [:create] do
    resource :password,
      controller: "clearance/passwords",
      only: [:create, :edit, :update]
  end

  get "/sign_in" => "clearance/sessions#new", as: "sign_in"
  delete "/sign_out" => "clearance/sessions#destroy", as: "sign_out"
  get "/sign_up" => "clearance/users#new", as: "sign_up"

  # To display a working link to sign users out of the admin dashboard,
  # rails-admin expects a `logout_path` route helper to exist which will sign
  # them out; this declaration defines this.
  delete :logout, to: 'clearance/sessions#destroy'

  constraints Clearance::Constraints::SignedIn.new { |user| user.admin? } do
    root 'rails_admin/main#dashboard'
  end

  constraints Clearance::Constraints::SignedIn.new do
    root 'home#index'

    resources :cases, only: [:new, :index, :create] do
      member do
        post :archive
      end
    end

    resources :clusters, only: :show
    resources :components, only: :show
  end

  constraints Clearance::Constraints::SignedOut.new do
    root 'clearance/sessions#new'
  end
end
