class ComponentType < ApplicationRecord
  has_many :components
  has_many :case_categories

  validates :name, presence: true
end
