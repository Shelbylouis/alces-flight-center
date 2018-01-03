class ComponentMake < ApplicationRecord
  belongs_to :component_type
  has_many :component_groups
end
