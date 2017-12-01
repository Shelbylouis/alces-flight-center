class Service < ApplicationRecord
  include ClusterPart

  belongs_to :service_type
  belongs_to :cluster

  delegate :description, to: :service_type

  def case_form_json
    {
      id: id,
      name: name,
      supportType: support_type,
      serviceType: service_type.case_form_json,
    }
  end
end
