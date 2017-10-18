
class AssetRecordField::Validator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    validate_associated_with_component_xor_group

    # Following validations check record is valid given asset, so return now if
    # no asset (record will be invalid from above validation anyway).
    return unless record.asset

    validate_definition_associated_with_component_type
    validate_field_settable_at_level
  end

  private

  def validate_associated_with_component_xor_group
    if !record.asset
      record.errors.add(
        :base,
        'must be associated with either component or component group'
      )
    elsif record.component && record.component_group
      record.errors.add(
        :base,
        'can only be associated with either component or component group, but not both'
      )
    end
  end

  def validate_definition_associated_with_component_type
    unless available_field_definitions.include?(record.definition)
      record.errors.add(
        :asset_record_field_definition,
        'is not a field definition associated with component type'
      )
    end
  end

  def available_field_definitions
    record.component_type.asset_record_field_definitions
  end

  def validate_field_settable_at_level
    # It is not possible to define an asset record field associated with a
    # ComponentGroup if the field definition states it is not settable at a
    # group-level.
    if record.component_group && !record.definition.settable_for_group?
      record.errors.add(
        :asset_record_field_definition,
        'this field is only settable at the component-level'
      )
    end
  end
end
