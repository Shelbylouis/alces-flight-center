class Component < ApplicationRecord
  TYPES = ['server', 'disk array', 'switch']
  belongs_to :cluster
  validates_associated :cluster
  validates :name, presence: true
  validates :component_type, inclusion: { in: TYPES }
end