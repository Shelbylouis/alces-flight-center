class Component < ApplicationRecord
  include AdminConfig
  include HasSupportType

  ASSET_RECORD_FIELD_REGEX_PREFIX =
    /^#{AssetRecordFieldDefinition::IDENTIFIER_ROOT}_(\d+)/
  ASSET_RECORD_FIELD_READER_REGEX = /#{ASSET_RECORD_FIELD_REGEX_PREFIX}$/
  ASSET_RECORD_FIELD_WRITER_REGEX = /#{ASSET_RECORD_FIELD_REGEX_PREFIX}=$/

  SUPPORT_TYPES = SupportType::VALUES + ['inherit']

  belongs_to :component_group
  has_one :component_type, through: :component_group
  has_one :cluster, through: :component_group
  has_many :asset_record_fields

  validates_associated :component_group
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true

  def support_type
    super == 'inherit' ? cluster.support_type : super
  end

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def case_form_json
    {
      id: id,
      name: name,
      supportType: support_type,
    }
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
        AssetRecordField.new(definition: definition, value: '')]
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
