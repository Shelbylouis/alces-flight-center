class AssetRecordField < ApplicationRecord
  belongs_to :asset_record_field_definition
  belongs_to :component, optional: true
  belongs_to :component_group, optional: true

  # Field value can be an empty string, but not null.
  validates :value, exclusion: { in: [nil] }

  validate :associated_with_component_xor_group
  validate :definition_associated_with_component_type
  validate :field_settable_at_level

  private

  def associated_with_component_xor_group
    if !(component || component_group)
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
    # We do not have a component_type => we have neither an associated
    # Component nor an associated ComponentGroup => this validation is not
    # relevant; this situation will be caught by
    # associated_with_component_xor_group validation.
    return unless component_type

    if !available_field_definitions.include?(asset_record_field_definition)
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
    # The ComponentType associated with either the associated Component's
    # ComponentGroup, or the associated ComponentGroup, depending on which of
    # these model's this AssetRecordField has an association with.
    component&.component_group&.component_type ||
      component_group&.component_type
  end

  def field_settable_at_level
    # It is not possible to define an asset record field associated with a
    # ComponentGroup if the field definition states it is not settable at a
    # group-level.
    if component_group && !asset_record_field_definition.settable_for_group?
      errors.add(
        :asset_record_field_definition,
        'this field is only settable at the component-level'
      )
    end
  end
end
