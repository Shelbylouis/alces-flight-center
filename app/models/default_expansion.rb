class DefaultExpansion < Expansion
  include AdminConfig::DefaultExpansion

  belongs_to :component_make

  validates :component_make, presence: true
  validates :component_id, absence: true

  def self.globally_available?
    true
  end
end
