class Service < ApplicationRecord
  include HasInheritableSupportType
  include HasMaintenanceWindows

  belongs_to :service_type
  belongs_to :cluster
  has_many :cases
  has_many :maintenance_windows

  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true

  delegate :description, to: :service_type

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def case_form_json
    {
      id: id,
      name: name,
      supportType: support_type,
      serviceType: service_type.case_form_json,
    }
  end

  # XXX duplicated from Component.
  def under_maintenance?
    cases.select(&:under_maintenance?).present?
  end
end
