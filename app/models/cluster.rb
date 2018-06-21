class Cluster < ApplicationRecord
  include AdminConfig::Cluster
  include HasSupportType
  include MarkdownDescription

  SUPPORT_TYPES = SupportType::VALUES
  PART_NAMES = [:component, :service].freeze

  belongs_to :site
  has_many :component_groups,
    # Associated ComponentGroups should be ordered by the `ordering` defined
    # for their types (we always want VMs to appear first etc.).
    -> {  joins(:component_type).order('ordering')  },
    dependent: :destroy
  has_many :components,
    # Need to remove order scope defined for ComponentGroups above, as makes no
    # sense and blows things up when just getting Components through the
    # groups.
    -> { unscope(:order) },
    through: :component_groups,
    dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :cases
  has_many :maintenance_windows
  has_many :logs, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :credit_deposits
  has_many :credit_charges, through: :cases

  validates_associated :site
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
  validates :canonical_name, presence: true
  validate :validate_all_cluster_parts_advice, if: :advice?
  validates :shortcode, presence: true, uniqueness: true
  validates_presence_of :motd

  before_validation CanonicalNameCreator.new, on: :create

  after_create :create_automatic_services

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def documents_path
    File.join(
      ENV.fetch('AWS_DOCUMENTS_PREFIX'),
      site.canonical_name,
      canonical_name
    )
  end

  def documents
    @documents ||= DocumentsRetriever.retrieve(documents_path)
  end

  def available_component_group_types
    component_groups.pluck("component_types.name").uniq
  end

  def unfinished_related_maintenance_windows
    parts = [self, *components, *services]
    parts
      .map(&:maintenance_windows)
      .flat_map(&:unfinished)
      .sort_by(&:created_at)
      .reverse
  end

  def next_case_index
    with_lock do  # Prevent concurrent reads of this record
      self.case_index = case_index + 1
      save!
      case_index
    end
  end

  def credit_balance
    deposits = credit_deposits.reduce(0) do |total, deposit|
      total += deposit.amount
    end

    credit_charges.reduce(deposits) do |total, kase|
      total -= kase.amount
    end
  end

  private

  def validate_all_cluster_parts_advice
    ['components', 'services'].each do |cluster_part|
      unless self.public_send(cluster_part).all?(&:advice?)
        errors.add(:base, "advice Cluster cannot be associated with managed #{cluster_part.capitalize}")
      end
    end
  end

  def create_automatic_services
    ServiceType.automatic.each do |service_type|
      services.create!(name: service_type.name, service_type: service_type)
    end
  end
end
