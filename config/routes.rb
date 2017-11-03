Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  mount RailsEmailPreview::Engine, at: 'emails' if Rails.env.development?

  get '/reset-password' => 'passwords#new', as: 'passwords'
  post '/reset-password' => 'passwords#create'

  # URL to complete password reset process. This will cause a user's password
  # to be changed (given the correct params), but `get` must be used as it will
  # be reached from an email.
  get '/reset-password/complete' => 'passwords#reset_complete'

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

    resources :clusters, only: :show do
      resources :cases, only: :new
    end

    resources :components, only: :show do
      resources :cases, only: :new
    end

    resources :services, only: :show do
      resources :cases, only: :new
    end
  end

  constraints Clearance::Constraints::SignedOut.new do
    root 'clearance/sessions#new', as: 'sign_in'
    post '/' => 'clearance/sessions#create', as: 'session'
  end
end
