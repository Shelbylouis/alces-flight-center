class Component < ApplicationRecord
  belongs_to :cluster
  belongs_to :component_type

  validates_associated :cluster
  validates :name, presence: true
end
