class ComponentType < ApplicationRecord
  include AdminConfig::ComponentType

  has_many :component_makes
  has_many :component_groups, through: :component_makes
  has_and_belongs_to_many :asset_record_field_definitions

  validates :name, presence: true
  validates :ordering, presence: true

  def self.globally_available?
    true
  end

  def asset_record_hash
    asset_record_field_definitions.map do |definition|
      new_field = AssetRecordField.new(definition: definition, value: '')
      [definition.id, new_field]
    end.to_h
  end
end
