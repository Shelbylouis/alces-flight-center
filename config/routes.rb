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

  asset_record = Proc.new do
    resource :asset_record, path: 'asset-record', only: [:edit, :update]
  end
  logs = Proc.new do
    resources :logs, only: :index
  end
  admin_logs = Proc.new do
    resources :logs, only: :create
  end
  maintenance_form = Proc.new do
    resources :maintenance_windows, only: :new do
      collection do
        # Do not define route helper (by passing `as: nil`) as otherwise this
        # will overwrite the `${model}_maintenance_windows_path` helper, as by
        # default `resources` expects `new` and `index` to use the same route.
        # However we do not want this, and this route can be accessed using the
        # `new_${model}_maintenance_windows_path` helper.
        post 'new', action: :create, as: nil
      end
    end
  end

  constraints Clearance::Constraints::SignedIn.new { |user| user.admin? } do
    root 'sites#index'
    resources :sites, only: [:show, :index] do
      resources :cases, only: [:new, :index, :show]
    end

    resources :cases, only: []

    resources :clusters, only: []  do
      maintenance_form.call
      admin_logs.call
    end

    resources :components, only: []  do
      maintenance_form.call
      resource :component_expansion,
               path: 'expansions',
               only: [:edit, :update, :create]
      asset_record.call
      admin_logs.call
    end

    resources :component_expansions, only: [:destroy]

    resources :component_groups, path: 'component-groups', only: [] do
      asset_record.call
    end

    resources :services, only: []  do
      maintenance_form.call
    end

    resources :maintenance_windows, only: [] do
      member do
        post :cancel
      end
    end

    resources :credit_charges, only: [:create, :update]

    # To display a working link to sign users out of the admin dashboard,
    # rails-admin expects a `logout_path` route helper to exist which will sign
    # them out; this declaration defines this.
    delete :logout, to: 'clearance/sessions#destroy'
  end

  constraints Clearance::Constraints::SignedIn.new do
    root 'sites#show'
    delete '/sign_out' => 'clearance/sessions#destroy', as: 'sign_out'

    resources :cases, only: [:new, :index, :show, :create] do
      member do
        post :archive
        post :restore
      end
    end

    resources :clusters, only: :show do
      resources :cases, only: [:index, :new]
      resources :services, only: :index
      resources :consultancy, only: :new
      resources :maintenance_windows, only: :index
      resources :components, only: :index
      logs.call
    end

    resources :components, only: :show do
      resources :cases, only: :new
      resources :consultancy, only: :new
      logs.call
    end

    resources :component_groups, path: 'component-groups', only: :show

    resources :services, only: :show do
      resources :cases, only: :new
      resources :consultancy, only: :new
    end

    resources :maintenance_windows, only: [] do
      member do
        post :confirm
        post :reject
      end
    end
  end

  constraints Clearance::Constraints::SignedOut.new do
    root 'clearance/sessions#new', as: 'sign_in'
    post '/' => 'clearance/sessions#create', as: 'session'
  end

  # Routes defined here are only defined/used in certain tests which need
  # access to special routes/controllers.
  if Rails.env.test?
    resource :request_test, only: :show
  end
end
