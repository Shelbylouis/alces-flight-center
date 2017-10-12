class ComponentType < ApplicationRecord
  has_many :component_groups
  has_many :case_categories
  has_and_belongs_to_many :asset_record_field_definitions

  validates :name, presence: true
end
