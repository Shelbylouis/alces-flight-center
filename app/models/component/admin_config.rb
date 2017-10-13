
module Component::AdminConfig
  extend ActiveSupport::Concern

  included do
    rails_admin do

      edit do
	# Define a textarea for every AssetRecordFieldDefinition when
	# creating/editing a Component. A Component instance responds to unique
	# reader/writer methods for every AssetRecordFieldDefinition, allowing
	# RailsAdmin to transparently call the methods it expects to exist for
	# and have the behaviour we want to happen occur.
	AssetRecordFieldDefinition.all_identifiers.map do |definition_identifier|
	  self.instance_exec do
	    configure definition_identifier, :text do

	      html_attributes rows: 5, cols: 100

	      definition = AssetRecordFieldDefinition.definition_for_identifier(
		definition_identifier
	      )
	      label definition.field_name

	      # If this AssetRecordFieldDefinition is not associated with the
	      # current Component's ComponentType, then do not include this
	      # field.
	      visible do
		bindings[:object].definition_identifiers.include?(definition_identifier)
	      end
	    end
	  end
	end
      end

    end
  end
end
