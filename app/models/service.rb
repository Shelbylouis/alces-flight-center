class Service < ApplicationRecord
  include HasInheritableSupportType

  belongs_to :service_type
  belongs_to :cluster

  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end
end
