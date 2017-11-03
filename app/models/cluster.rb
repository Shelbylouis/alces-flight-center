class Cluster < ApplicationRecord
  include AdminConfig::Cluster
  include HasSupportType
  include MarkdownDescription

  SUPPORT_TYPES = SupportType::VALUES

  belongs_to :site
  has_many :component_groups, dependent: :destroy
  has_many :components, through: :component_groups, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :cases

  validates_associated :site
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
  validates :canonical_name, presence: true
  validate :validate_all_components_advice, if: :advice?

  before_validation CanonicalNameCreator.new, on: :create

  after_create :create_automatic_services

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
