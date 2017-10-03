class ComponentGroup < ApplicationRecord
  belongs_to :cluster
  belongs_to :component_type
  has_many :components

  validates :name, presence: true
end
