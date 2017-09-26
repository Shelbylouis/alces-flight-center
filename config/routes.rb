Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  constraints Clearance::Constraints::SignedIn.new do
    root 'home#show'
    resources :cases, except: [:destroy]
  end

  constraints Clearance::Constraints::SignedOut.new do
    root 'home#signed_out'
  end
end
