class Component < ApplicationRecord
  include AdminConfig::Component
  include ClusterPart

  include HasAssetRecord

  belongs_to :component_group
  has_one :component_type, through: :component_group
  has_one :cluster, through: :component_group
  has_many :asset_record_fields
  has_many :component_expansions
  has_many :logs

  has_one :component_make, through: :component_group
  has_many :default_expansions, through: :component_make

  validates_associated :component_group,
                       :asset_record_fields,
                       :component_expansions

  after_create :create_component_expansions_from_defaults

  def unfinished_related_maintenance_windows
    component = [self]
    component
      .map(&:maintenance_windows)
      .flat_map(&:unfinished)
      .sort_by(&:created_at)
      .reverse
  end

  private

  def create_component_expansions_from_defaults
    default_expansions.each do |d|
      data = d.slice(:expansion_type, :slot, :ports)
      component_expansions.create!(**data.symbolize_keys)
    end
  end

  def asset_record_parent
    component_group
  end
end
