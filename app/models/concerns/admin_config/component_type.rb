
module AdminConfig::ComponentType
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :component_groups do
          hide
        end
        configure :component_makes do
          hide
        end
        configure :asset_record_field_definitions do
          hide
        end
      end
    end
  end
end
