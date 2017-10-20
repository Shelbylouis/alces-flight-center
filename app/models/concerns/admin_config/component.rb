
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
        AdminConfig::Shared::EditableAssetRecordFields.define_asset_record_fields(self)

        configure :asset_record_fields do
          hide
        end
        configure :component_type do
          hide
        end
        configure :cluster do
          hide
        end
      end
    end
  end
end
