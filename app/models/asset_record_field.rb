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
    # The ComponentType associated with either the associated Component's
    # ComponentGroup, or the associated ComponentGroup, depending on which of
    # these model's this AssetRecordField has an association with.
    component&.component_group&.component_type ||
      component_group&.component_type
  end

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
      readable_asset_description = asset.class.to_s.tableize.humanize(capitalize: false).pluralize(1)
      errors.add(
        :base,
        "a field for this definition already exists for this #{readable_asset_description}, you should edit the existing field"
      )
    end
  end
end
