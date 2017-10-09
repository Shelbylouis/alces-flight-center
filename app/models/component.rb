class Component < ApplicationRecord
  SUPPORT_TYPES = Issue::SUPPORT_TYPES + ['inherit']

  belongs_to :component_group
  has_one :component_type, through: :component_group
  has_one :cluster, through: :component_group

  validates_associated :component_group
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true

  def support_type
    super == 'inherit' ? cluster.support_type : super
  end

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def case_form_json
    {
      id: id,
      name: name,
    }
  end
end
