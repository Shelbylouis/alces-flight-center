class Cluster < ApplicationRecord
  include AdminConfig::Cluster
  include HasSupportType
  include MarkdownDescription

  SUPPORT_TYPES = SupportType::VALUES
  PART_NAMES = [:component, :service].freeze

  belongs_to :site
  has_many :component_groups, dependent: :destroy
  has_many :components, through: :component_groups, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :cases

  has_many :maintenance_window_associations, as: :associated_element
  has_many :maintenance_windows, through: :maintenance_window_associations

  has_many :logs, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :credit_deposits
  has_many :credit_charges, through: :cases
  has_many :cluster_checks
  has_many :checks, through: :cluster_checks
  has_many :check_results, through: :cluster_checks

  has_many :service_plans
  has_many :terminal_services, class_name: 'ClusterTerminalService'

  validates_associated :site
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
  validates :canonical_name, presence: true
  validate :validate_all_cluster_parts_advice, if: :advice?
  validates :shortcode, presence: true, uniqueness: true

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

  def unfinished_related_maintenance_windows
    parts = [self, *components, *component_groups, *services]
    parts
      .map(&:maintenance_windows)
      .flat_map(&:unfinished)
      .uniq
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

  def to_param
    shortcode.parameterize.upcase
  end

  def self.find_from_id!(id)
    if /^[0-9]+$/.match(id)
      Cluster.find(id)
    else
      Cluster.find_by_shortcode!(id)
    end
  end

  def cluster_check_count
    cluster_checks.length
  end

  def resolved_cases_count
    self.cases.where(state: 'resolved').count
  end

  def current_service_plan
    service_plans.where(
      'start_date <= ? AND end_date >= ?',
      Date.current,
      Date.current
    ).first
  end

  def previous_service_plan
    service_plans.where('end_date < ?', Date.current)
                 .order(:start_date)
                 .last
  end

  def service_plans_covering(from, to)
    service_plans.where(start_date: from..to)
      .or(service_plans.where(end_date: from..to))
      .or(
        service_plans.where(
          'start_date <= ? AND end_date >= ?',
          from,
          to
        )
      ).order(:start_date)
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
