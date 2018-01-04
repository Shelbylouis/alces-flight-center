class ComponentMake < ApplicationRecord
  belongs_to :component_type
  has_many :component_groups

  validates :manufacturer, :model, :knowledgebase_url, presence: true
end
