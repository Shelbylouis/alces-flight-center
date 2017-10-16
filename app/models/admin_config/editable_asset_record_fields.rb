
module AdminConfig
  module EditableAssetRecordFields
    extend ActiveSupport::Concern

    ASSET_RECORD_FIELD_REGEX_PREFIX =
      /^#{AssetRecordFieldDefinition::IDENTIFIER_ROOT}_(\d+)/
    ASSET_RECORD_FIELD_READER_REGEX = /#{ASSET_RECORD_FIELD_REGEX_PREFIX}$/
    ASSET_RECORD_FIELD_WRITER_REGEX = /#{ASSET_RECORD_FIELD_REGEX_PREFIX}=$/

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

    def definition_identifiers
      component_type.asset_record_field_definitions.map(&:identifier)
    end

    def respond_to?(method, include_private=false)
      if method.match?(ASSET_RECORD_FIELD_READER_REGEX) ||
          method.match?(ASSET_RECORD_FIELD_WRITER_REGEX)
        true
      else
        super
      end
    end

    def method_missing(method, *args, &block)
      # Can obtain an associated AssetRecordField given a method call unique to
      # each AssetRecordFieldDefinition which looks like a reader method.
      method.match(ASSET_RECORD_FIELD_READER_REGEX) do |match|
        return asset_record_field_value(definition_id: match[1])
      end

      # Similarly can appropriately create/update/delete an associated
      # AssetRecordField given a method call unique to each
      # AssetRecordFieldDefinition which looks like a writer method.
      method.match(ASSET_RECORD_FIELD_WRITER_REGEX) do |match|
        assign_asset_record_field_value(
          definition_id: match[1], value: args.first
        )
        return
      end

      super
    end

    private


    def asset_record_field_value(definition_id:)
      asset_record_fields
        .find_by_asset_record_field_definition_id(definition_id)
      &.value
    end

    def assign_asset_record_field_value(definition_id:, value:)
      field = asset_record_fields.find_or_initialize_by(
        asset_record_field_definition_id: definition_id
      )

      if value.strip.empty?
        # If we've been sent an empty value, destroy any current AssetRecordField
        # so asset record falls back to next level up.
        field.destroy!
      else
        # Otherwise create/update AssetRecordField for given definition with
        # given value.
        field.value = value
        field.save!
      end
    end
  end
end
