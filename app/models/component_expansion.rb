class ComponentExpansion < Expansion
  belongs_to :component
  delegate :site, to: :component

  validates :component, presence: true
  validates :component_make_id, absence: true
end
