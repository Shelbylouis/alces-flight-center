class Issue < ApplicationRecord
  include AdminConfig::Issue

  class << self
    def globally_available?
      true
    end

    private

    def define_finder_method(identifier)
      method_name = "#{identifier}_issue"
      define_singleton_method method_name do
        find_by_identifier(identifier)
      end
    end
  end

  IDENTIFIER_NAMES = [
    :request_component_becomes_advice,
    :request_component_becomes_managed,
    :request_service_becomes_advice,
    :request_service_becomes_managed,
    :cluster_consultancy,
    :component_consultancy,
    :service_consultancy,
  ]

  # We need to be able to find and use certain Issues in custom ways; the
  # concept of optional, unique identifiers (including the following) allows us
  # to do this, while still allowing all Issues to be treated as user-editable
  # data.
  IDENTIFIERS = IDENTIFIER_NAMES.map do |identifier|
    define_finder_method(identifier)
    [identifier, identifier.to_s]
  end.to_h.to_struct

  belongs_to :category, required: false
  belongs_to :service_type, required: false
  has_many :cases
  has_many :tiers

  validates :name, presence: true
  validates :identifier, uniqueness: true, if: :identifier
  validates :chargeable, inclusion: {in: [true, false]}

  validates :service_type,
            absence: {
              message: 'can only require particular service type if issue requires service',
            },
            unless: :requires_service

  after_create :create_standard_consultancy_tier

  def special?
    IDENTIFIER_NAMES.include?(identifier&.to_sym)
  end

  def default_subject
    name
  end

  private

  def create_standard_consultancy_tier
    # By default we want to support the creation of a Tier 3/consultancy Case,
    # with the ability to provide any arbitrary details, for every Issue.
    self.tiers.create!(
      level: 3,
      fields: [
        {
          type: 'textarea',
          name: 'Details',
        }
      ]
    )
  end
end
