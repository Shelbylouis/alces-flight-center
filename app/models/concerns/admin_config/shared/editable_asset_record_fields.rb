
module AdminConfig::Shared
  module EditableAssetRecordFields
    extend ActiveSupport::Concern

    ASSET_RECORD_FIELD_REGEX_PREFIX =
      /^#{::AssetRecordFieldDefinition::IDENTIFIER_ROOT}_(\d+)/
    ASSET_RECORD_FIELD_READER_REGEX = /#{ASSET_RECORD_FIELD_REGEX_PREFIX}$/
    ASSET_RECORD_FIELD_WRITER_REGEX = /#{ASSET_RECORD_FIELD_REGEX_PREFIX}=$/

    # - `admin_config_context` = `self` within the `rails_admin do edit do ...`
    # block we are defining the fields in.
    # - `field_disabled` = Proc which takes an `AssetRecordFieldDefinition`
    # instance and returns whether the field for setting this definition should
    # be disabled; defaults to no fields being disabled.
    def self.define_asset_record_fields(
      admin_config_context,
      field_disabled: lambda { |_definition| false }
    )
      # Define a textarea for every AssetRecordFieldDefinition when
      # creating/editing an object with associated AssetRecordFields. By
      # including the EditableAssetRecordFields module in the object's class,
      # it will respond to unique reader/writer methods for every
      # AssetRecordFieldDefinition, allowing RailsAdmin to transparently call
      # the methods it expects to exist and have the behaviour we want to
      # happen occur.
      ::AssetRecordFieldDefinition.all_identifiers.map do |definition_identifier|
        admin_config_context.instance_exec do
          configure definition_identifier, :text do
            definition = ::AssetRecordFieldDefinition.definition_for_identifier(
              definition_identifier
            )

            disabled = field_disabled.call(definition)

            # Currently only a single reason that a field might be disabled
            # exists; if more are added we should extract the reason displayed
            # as title text from being hard-coded here.
            title = if disabled
                      'This field can only be set at the individual Component level'
                    else
                      nil
                    end

            html_attributes rows: 5,
              cols: 100,
              disabled: disabled,
              title: title

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

    def definition_identifiers
      # Guard needed as when creating a new record of the model this module is
      # included in we will not yet know what the component type will be, and
      # so we cannot yet know what AssetRecordFieldDefinitions will be
      # available.
      return [] unless component_type
      component_type.asset_record_field_definitions.map(&:identifier)
    end

    def respond_to?(method, include_private = false)
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
      field = asset_record_fields.find_by(
        asset_record_field_definition_id: definition_id
      )

      value_present = value.strip.present?

      if field && value_present
        # We have an existing AssetRecordField and have received a new value,
        # so update it.
        field.value = value
        field.save!
      elsif field
        # We have an existing AssetRecordField and the new value is empty, so
        # delete it so asset record falls back to next level up.
        field.destroy!
      elsif value_present
        # We don't have an existing AssetRecordField and have received a new
        # value, so create it.
        asset_record_fields.create!(
          asset_record_field_definition_id: definition_id,
          value: value
        )
      end
    end
  end
end
