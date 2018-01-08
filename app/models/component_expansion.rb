class ComponentExpansion < Expansion
  belongs_to :component
  delegate :site, to: :component
end
