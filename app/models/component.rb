class Component < ApplicationRecord
  include AdminConfig::Component
  include AdminConfig::Shared::EditableAssetRecordFields
  include ClusterPart

  belongs_to :component_group
  has_one :component_type, through: :component_group
  has_one :cluster, through: :component_group
  has_many :asset_record_fields
  has_many :component_expansions

  has_one :component_make, through: :component_group
  has_many :default_expansions, through: :component_make

  validates_associated :component_group,
                       :asset_record_fields,
                       :component_expansions

  after_create :create_component_expansions_from_defaults

  def asset_record
    # Merge asset record layers to obtain hash for this Component of all
    # asset record fields for this ComponentType; fields set in later layers
    # will take precedence over those in earlier layers for the same
    # definition.
    @asset_record ||=
      asset_record_layers.reduce({}, :merge).values.map do |field|
        [field.name, field.value]
      end.to_h
  end

  private

  def create_component_expansions_from_defaults
    default_expansions.each do |d|
      data = d.slice(:expansion_type, :slot, :ports)
      component_expansions.create!(**data.symbolize_keys)
    end
  end

  # Method to be called from AdminConfig to format Component asset record for
  # displaying to admins.
  def asset_record_view
    asset_record.to_json
  end

  def asset_record_layers
    # Each entry is a hash of definition ID to asset record field.
    [
      empty_asset_record_fields,
      group_asset_record_fields,
      component_asset_record_fields,
    ]
  end

  def empty_asset_record_fields
    component_type.asset_record_field_definitions.map do |definition|
      [
        definition.id,
        # Placeholder empty AssetRecordField.
        AssetRecordField.new(definition: definition, value: ''),
      ]
    end.to_h
  end

  def group_asset_record_fields
    extract_asset_record_fields(component_group)
  end

  def component_asset_record_fields
    extract_asset_record_fields(self)
  end

  def extract_asset_record_fields(model)
    model.asset_record_fields.map do |field|
      [field.definition.id, field]
    end.to_h
  end
end
