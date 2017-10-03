class ComponentType < ApplicationRecord
  has_many :component_groups
  has_many :case_categories

  validates :name, presence: true
end
