
module ClusterPart
  extend ActiveSupport::Concern

  include HasSupportType

  SUPPORT_TYPES = SupportType::VALUES + ['inherit']

  included do
    has_many :cases
    has_many :maintenance_windows

    validates :name, presence: true
    validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
    validates :internal, inclusion: {in: [true, false]}

    delegate :site, to: :cluster
  end

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def support_type
    super == 'inherit' ? cluster.support_type : super
  end

  def case_form_json
    {
      id: id,
      name: name,
      supportType: support_type,
    }
  end

  def unfinished_related_maintenance_windows
    maintenance_windows.unfinished
      .sort_by(&:created_at)
      .reverse
  end
end
