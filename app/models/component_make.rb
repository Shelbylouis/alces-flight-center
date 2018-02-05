class ComponentMake < ApplicationRecord
  include AdminConfig::ComponentMake

  belongs_to :component_type
  has_many :component_groups
  has_many :default_expansions

  validates :manufacturer, :model, :knowledgebase_url, presence: true

  def name
    "#{manufacturer} : #{model}"
  end

  def self.globally_available?
    true
  end
end
