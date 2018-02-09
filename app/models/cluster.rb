class Cluster < ApplicationRecord
  include AdminConfig::Cluster
  include HasSupportType
  include MarkdownDescription
  include HasMaintenanceWindows

  SUPPORT_TYPES = SupportType::VALUES

  belongs_to :site
  has_many :component_groups, dependent: :destroy
  has_many :components, through: :component_groups, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :cases
  has_many :credit_deposits
  has_many :credit_charges, through: :cases
  has_many :maintenance_windows
  has_many :cluster_logs, dependent: :destroy

  validates_associated :site
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
  validates :canonical_name, presence: true
  validate :validate_all_components_advice, if: :advice?

  before_validation CanonicalNameCreator.new, on: :create

  after_create :create_automatic_services

  # So can get the Cluster for the associated model for a Case, even if the
  # associated model is the Cluster itself.
  def cluster
    self
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
      components: components.map(&:case_form_json),
      services: services.map(&:case_form_json),
      supportType: support_type,
      chargingInfo: charging_info,
      credits: credits
    }
  end

  def managed_components
    components.select(&:managed?)
  end

  def advice_components
    components.select(&:advice?)
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

  def component_groups_by_type
    component_groups.group_by do |group|
      group.component_type
    end.map do |component_type, groups|
      {
        name: component_type.name,
        ordering: component_type.ordering,
        component_groups: groups
      }.to_struct
    end.sort_by(&:ordering)
  end

  def credits
    deposits = credit_deposits.reduce(0) do |total, deposit|
      total += deposit.amount
    end
    credit_charges.reduce(deposits) do |total, charge|
      total -= charge.amount
    end
  end

  def open_related_maintenance_windows
    parts = [self, *components, *services]
    parts.flat_map(&:open_maintenance_windows).sort_by(&:created_at).reverse
  end

  private

  def validate_all_components_advice
    unless components.all?(&:advice?)
      errors.add(:base, 'advice Cluster cannot be associated with managed Components')
    end
  end

  def create_automatic_services
    ServiceType.automatic.each do |service_type|
      services.create!(name: service_type.name, service_type: service_type)
    end
  end
end
