
module AdminConfig::ComponentGroup
  extend ActiveSupport::Concern

  included do
    rails_admin do
      list do
        configure :genders_host_range do
          hide
        end
      end

      edit do
        AdminConfig::Shared::EditableAssetRecordFields.define_asset_record_fields(self)

        configure :genders_host_range do
          help <<-EOF
            Specify a genders host range to have the corresponding components
            be generated if they do not already exist, e.g. entering
            `node[01-03]` will cause components with names `node01`, `node02`,
            and `node03` to be generated. See
            https://github.com/chaos/genders/blob/master/TUTORIAL#L72,L87 for
            details of host range syntax.
          EOF
        end

        configure :components do
          hide
        end
        configure :asset_record_fields do
          hide
        end
      end
    end
  end
end
