Rails.application.routes.draw do
  asset_record_alias = 'asset-record'
  component_expansions_alias = 'expansions'
  component_groups_alias = 'component-groups'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  mount RailsEmailPreview::Engine, at: 'emails' if Rails.env.development?

  get '/reset-password' => 'passwords#new', as: 'passwords'
  post '/reset-password' => 'passwords#create'

  # URL to complete password reset process. This will cause a user's password
  # to be changed (given the correct params), but `get` must be used as it will
  # be reached from an email.
  get '/reset-password/complete' => 'passwords#reset_complete'

  asset_record_view = Proc.new {
    resource :asset_record, path: asset_record_alias, only: :show
  }
  asset_record_form = Proc.new do
    resource :asset_record, path: asset_record_alias, only: [:edit, :update]
  end

  logs = Proc.new do
    resources :logs, only: :index
  end
  admin_logs = Proc.new do
    resources :logs, only: :create
  end

  request_maintenance_form = Proc.new do
    resources :maintenance_windows, path: :maintenance, only: :new do
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
  confirm_maintenance_form = Proc.new do
    resources :maintenance_windows, path: :maintenance, only: [] do
      member do
        get :confirm
        patch :confirm, to: 'maintenance_windows#confirm_submit'
      end
    end
  end

  archive_cases = Proc.new do |**params, &block|
    params[:only] = Array.wrap(params[:only]).concat [:new, :index]
    resources :cases, **params do
      collection do
        get :archives
      end
      block.call if block
    end
  end

  constraints Clearance::Constraints::SignedIn.new { |user| user.admin? } do
    root 'sites#index'
    resources :sites, only: [:show, :index] do
      archive_cases.call(only: :show)
    end

    resources :clusters, only: []  do
      request_maintenance_form.call
      admin_logs.call
    end

    resources :components, only: []  do
      request_maintenance_form.call
      resource :component_expansion,
               path: component_expansions_alias,
               only: [:edit, :update, :create]
      asset_record_form.call
      admin_logs.call
    end

    resources :component_expansions, only: [:destroy]

    resources :component_groups, path: component_groups_alias, only: [] do
      asset_record_form.call
    end

    resources :services, only: []  do
      request_maintenance_form.call
    end

    resources :maintenance_windows, path: :maintenance, only: [] do
      member do
        post :cancel
        post :end
        post :extend
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

    archive_cases.call(only: [:show, :create]) do
      member do
        post :archive
        post :restore
      end
      resources :case_comments, only: :create
    end

    resources :clusters, only: :show do
      archive_cases.call
      resources :services, only: :index
      resources :consultancy, only: :new
      resources :maintenance_windows, path: :maintenance, only: :index
      resources :components, only: :index
      logs.call
      confirm_maintenance_form.call
    end

    resources :components, only: :show do
      archive_cases.call
      resources :consultancy, only: :new
      resources :component_expansions,
                path: component_expansions_alias,
                only: :index
      asset_record_view.call
      logs.call
      confirm_maintenance_form.call
    end

    resources :component_groups, path: component_groups_alias, only: [] do
      get '/', controller: :components, action: :index
      resources :components, only: :index
      asset_record_view.call
    end

    resources :services, only: :show do
      archive_cases.call
      resources :consultancy, only: :new
      confirm_maintenance_form.call
    end

    resources :maintenance_windows, path: :maintenance, only: [] do
      member do
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
