
module AdminConfig::Log
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :site do
          hide
        end
        configure :cases do
          hide
        end
      end
    end
  end
end
