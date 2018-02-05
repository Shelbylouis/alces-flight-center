
module AdminConfig::Service
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :cases do
          hide
        end
        configure :maintenance_windows do
          hide
        end
      end
    end
  end
end
