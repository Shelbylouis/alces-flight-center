
module AdminConfig::Issue
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :identifier do
          hide
        end
        configure :cases do
          hide
        end
        configure :tiers do
          hide
        end
      end
    end
  end
end
