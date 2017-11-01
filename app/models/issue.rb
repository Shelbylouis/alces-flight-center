class Issue < ApplicationRecord
  include AdminConfig::Issue
  include HasSupportType

  SUPPORT_TYPES = SupportType::VALUES + ['advice-only']

  # We need to be able to find and use certain Issues in custom ways; the
  # concept of optional, unique identifiers (including the following) allows us
  # to do this, while still allowing all Issues to be treated as user-editable
  # data.
  IDENTIFIERS = {
    request_component_becomes_advice: 'request_component_becomes_advice',
    request_component_becomes_managed: 'request_component_becomes_managed',
    request_service_becomes_advice: 'request_service_becomes_advice',
    request_service_becomes_managed: 'request_service_becomes_managed',
  }.to_struct

  belongs_to :case_category
  validates :name, presence: true
  validates :details_template, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true
  validates :identifier, uniqueness: true, if: :identifier

  class << self
    def request_component_becomes_advice_issue
      find_by_identifier(IDENTIFIERS.request_component_becomes_advice)
    end

    def request_component_becomes_managed_issue
      find_by_identifier(IDENTIFIERS.request_component_becomes_managed)
    end

    def request_service_becomes_advice_issue
      find_by_identifier(IDENTIFIERS.request_service_becomes_advice)
    end

    def request_service_becomes_managed_issue
      find_by_identifier(IDENTIFIERS.request_service_becomes_managed)
    end
  end

  def advice_only?
    support_type == 'advice-only'
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
      detailsTemplate: details_template,
      requiresComponent: requires_component,
      supportType: support_type,
    }
  end
end
