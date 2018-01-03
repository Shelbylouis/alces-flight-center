class ComponentGroup < ApplicationRecord
  include AdminConfig::ComponentGroup
  include AdminConfig::Shared::EditableAssetRecordFields

  belongs_to :cluster
  has_one :site, through: :cluster
  belongs_to :component_make
  has_one :component_type, through: :component_make
  has_many :components, dependent: :destroy
  has_many :asset_record_fields

  validates :name, presence: true
  validates_associated :cluster, :asset_record_fields

  attr_accessor :genders_host_range

  after_save :create_needed_components_for_host_range

  def component_names
    components.map(&:name)
  end

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

  def create_needed_components_for_host_range
    new_node_names = expanded_genders_host_range - component_names

    new_node_names.map do |name|
      components.create!(name: name)
    end
  end

  def expanded_genders_host_range
    # Create a temporary genders file with a single line using the
    # `genders_host_range` and placeholder attribute, and use `nodeattr` to
    # expand a list of node names for this attribute.
    genders_attr = 'group'
    genders_line = [genders_host_range, genders_attr].join(' ')
    Tempfile.open do |file|
      file.write(genders_line)
      file.flush
      nodeattr_output = `nodeattr -f #{file.path} -c #{genders_attr}`
      nodeattr_output.strip.split(',')
    end
  end

  def asset_record_layers
    # Each entry is a hash of definition ID to asset record field.
    [
      empty_asset_record_fields,
      group_asset_record_fields,
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
    extract_asset_record_fields(self)
  end

  def extract_asset_record_fields(model)
    model.asset_record_fields.map do |field|
      [field.definition.id, field]
    end.to_h
  end
end
