class AssetRecordField < ApplicationRecord
  belongs_to :asset_record_field_definition
  belongs_to :component, optional: true
  belongs_to :component_group, optional: true

  alias_attribute :definition, :asset_record_field_definition

  # Field value can be an empty string, but not null.
  validates :value, exclusion: { in: [nil] }

  validate :associated_with_component_xor_group
  validate :definition_associated_with_component_type
  validate :field_settable_at_level
  validate :field_not_already_set

  def name
    definition.field_name
  end

  private

  def associated_with_component_xor_group
    if !asset
      errors.add(
        :base,
        'must be associated with either component or component group'
      )
    elsif component && component_group
      errors.add(
        :base,
        'can only be associated with either component or component group, but not both'
      )
    end
  end

  def definition_associated_with_component_type
    return unless asset

    if !available_field_definitions.include?(definition)
      errors.add(
        :asset_record_field_definition,
        'is not a field definition associated with component type'
      )
    end
  end

  def available_field_definitions
    component_type.asset_record_field_definitions
  end

  def component_type
    asset&.component_type
  end

  # An AssetRecordField should be associated with precisely one Component or
  # ComponentGroup (the asset).
  def asset
    component || component_group
  end

  def field_settable_at_level
    # It is not possible to define an asset record field associated with a
    # ComponentGroup if the field definition states it is not settable at a
    # group-level.
    if component_group && !definition.settable_for_group?
      errors.add(
        :asset_record_field_definition,
        'this field is only settable at the component-level'
      )
    end
  end

  def field_not_already_set
    return unless asset

    asset_field_definitions = asset.asset_record_fields.map(&:definition)
    if asset_field_definitions.include?(definition)
      errors.add(
        :base,
        "a field for this definition already exists for this #{asset.readable_model_name}, you should edit the existing field"
      )
    end
  end
end
