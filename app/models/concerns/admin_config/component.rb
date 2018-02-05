
module AdminConfig::Component
  extend ActiveSupport::Concern

  included do
    rails_admin do
      show do
        configure :asset_record_view do
          label 'Asset record'
          show
        end
      end

      edit do
        configure :asset_record_fields do
          hide
        end
        configure :component_type do
          hide
        end
        configure :cluster do
          hide
        end
        configure :cases do
          hide
        end
        configure :maintenance_windows do
          hide
        end
        configure :component_expansions do
          hide
        end
        configure :default_expansions do
          hide
        end
        configure :component_make do
          hide
        end
      end
    end
  end
end
