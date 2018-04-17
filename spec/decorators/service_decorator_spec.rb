require 'rails_helper'

RSpec.describe ServiceDecorator do
  describe '#change_support_type_button' do
    let! :request_advice_issue { create(:request_service_becomes_advice_issue) }
    let! :request_managed_issue { create(:request_service_becomes_managed_issue) }

    it 'gives nothing for internal Service' do
      service = create(:service, internal: true).decorate

      expect(service.change_support_type_button).to be nil
    end
  end

  describe '#links' do
    subject { create(:service).decorate }

    it 'includes link to Service' do
      expect(
        subject.links
      ).to include(
        h.link_to(subject.name, h.service_path(subject))
      )
    end

    it 'includes link to Cluster' do
      expect(
        subject.links
      ).to include(
        h.link_to(subject.cluster.name, h.cluster_path(subject.cluster))
      )
    end
  end

  describe '#case_form_buttons' do
    subject { create(:service).decorate }

    include_examples 'case_form_buttons', 'service'

    it 'includes link to Service Case form' do
      expect(subject.case_form_buttons).to include(
        h.new_service_case_path(service_id: subject.id)
      )
    end

    it 'includes link to Service consultancy form' do
      expect(subject.case_form_buttons).to include(
        h.new_service_consultancy_path(service_id: subject.id)
      )
    end
  end
end
