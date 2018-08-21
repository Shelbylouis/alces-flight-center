class ComponentGroup < ApplicationRecord
  include AdminConfig::ComponentGroup

  include BelongsToCluster

  belongs_to :cluster
  has_one :site, through: :cluster
  has_many :components, dependent: :destroy
  has_many :maintenance_window_associations, as: :associated_element
  has_many :maintenance_windows, through: :maintenance_window_associations

  has_many :case_associations, as: :associated_element
  has_many :cases, through: :case_associations

  validates :name, presence: true

  validates_associated :cluster

  def component_names
    components.map(&:name)
  end

  def component_type
    components.first&.component_type || 'component'
  end

end
