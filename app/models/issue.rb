class Issue < ApplicationRecord
  include AdminConfig::Issue
  include HasSupportType

  SUPPORT_TYPES = SupportType::VALUES + ['advice-only']

  class << self
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

  validates :name, presence: true
  validates :details_template, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
  validates :identifier, uniqueness: true, if: :identifier
  validates :chargeable, inclusion: {in: [true, false]}

  validates :service_type,
            absence: {
              message: 'can only require particular service type if issue requires service',
            },
            unless: :requires_service

  def advice_only?
    support_type == 'advice-only'
  end

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting support type.
  def support_type_enum
    SUPPORT_TYPES
  end

  def special?
    IDENTIFIER_NAMES.include?(identifier&.to_sym)
  end

  def case_form_json
    {
      id: id,
      name: name,
      detailsTemplate: details_template,
      requiresComponent: requires_component,
      requiresService: requires_service,
      serviceType: service_type&.case_form_json,
      supportType: support_type,
      chargeable: chargeable
    }
  end
end
