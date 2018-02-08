
module AdminConfig::ComponentExpansion
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :type do
          hide
        end
        configure :component_make_id do
          hide
        end
      end
    end
  end
end
