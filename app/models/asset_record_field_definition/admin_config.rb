
module AssetRecordFieldDefinition::AdminConfig
  extend ActiveSupport::Concern

  included do
    rails_admin do

      # Use `field_name` to label definitions; this is the clearest identifier
      # of what a definition is.
      object_label_method do
	:field_name
      end

    end
  end
end
