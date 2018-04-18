require 'rails_helper'

RSpec.describe ServiceDecorator do
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

  describe '#case_form_button' do
    subject { create(:service).decorate }

    it 'includes link to Service Case form' do
      expect(subject.case_form_button).to include(
        h.new_service_case_path(service_id: subject.id)
      )
    end
  end
end
