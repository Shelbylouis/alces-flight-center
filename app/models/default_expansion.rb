class DefaultExpansion < Expansion
  belongs_to :component_make

  def self.globally_available?
    true
  end
end
