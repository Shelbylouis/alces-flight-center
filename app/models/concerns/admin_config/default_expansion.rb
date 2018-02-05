
module AdminConfig::DefaultExpansion
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :type do
          hide
        end
        configure :component_id do
          hide
        end
      end
    end
  end
end
