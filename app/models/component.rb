class Component < ApplicationRecord
  belongs_to :component_group
  has_one :component_type, through: :component_group
  has_one :cluster, through: :component_group

  validates_associated :component_group
  validates :name, presence: true
end
