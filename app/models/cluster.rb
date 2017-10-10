class Cluster < ApplicationRecord
  SUPPORT_TYPES = Issue::SUPPORT_TYPES

  belongs_to :site
  has_many :component_groups, dependent: :destroy
  has_many :components, through: :component_groups, dependent: :destroy
  has_many :cases

  validates_associated :site
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def case_form_json
    {
      id: id,
      name: name,
      components: components.map(&:case_form_json),
    }
  end

  def managed_components
    components.select(&:managed?)
  end

  def advice_components
    components.select(&:advice?)
  end
end
