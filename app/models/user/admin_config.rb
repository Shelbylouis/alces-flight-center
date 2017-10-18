
module User::AdminConfig
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :password_confirmation do
          hide
        end
      end
    end
  end
end
