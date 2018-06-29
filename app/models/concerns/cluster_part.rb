
# Concern to hold shared behaviour for models which together make up an entire
# Cluster, and each is a single 'part' of the Cluster (rather than some
# collection of other parts or constituents of a single part); currently just
# used by Components and Services.
module ClusterPart
  extend ActiveSupport::Concern

  include HasSupportType
  include BelongsToCluster

  SUPPORT_TYPES = SupportType::VALUES + ['inherit']

  included do
    has_many :case_associations, as: :associated_element
    has_many :cases, through: :case_associations

    has_many :maintenance_windows

    validates :name, presence: true
    validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
    validates :internal, inclusion: {in: [true, false]}

    delegate :site, to: :cluster

    scope :managed, -> { select(&:managed?) }
    scope :advice, -> { select(&:advice?) }
  end

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def support_type
    super == 'inherit' ? cluster.support_type : super
  end

  def unfinished_related_maintenance_windows
    maintenance_windows.unfinished
      .sort_by(&:created_at)
      .reverse
  end
end
