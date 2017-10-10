class Issue < ApplicationRecord
  include HasSupportType

  SUPPORT_TYPES = ['managed', 'advice'].freeze

  belongs_to :case_category
  validates :name, presence: true
  validates :details_template, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }, presence: true

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
    }
  end
end
