class ComponentType < ApplicationRecord
  include AdminConfig::ComponentType

  has_many :component_groups
  has_and_belongs_to_many :asset_record_field_definitions

  validates :name, presence: true
end
