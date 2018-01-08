class ComponentMake < ApplicationRecord
  belongs_to :component_type
  has_many :component_groups
  has_many :default_expansions

  validates :manufacturer, :model, :knowledgebase_url, presence: true

  def self.globally_available?
    true
  end
end
