require 'rails_helper'

RSpec.describe ClusterDecorator do
  subject { create(:cluster).decorate }

  describe '#links' do
    it 'returns link to Cluster' do
      expect(
        subject.links
      ).to eq(
        h.link_to(subject.name, h.cluster_path(subject))
      )
    end
  end

  describe '#case_form_buttons' do
    include_examples 'case_form_buttons', 'cluster'

    it 'includes link to Cluster Case form' do
      expect(subject.case_form_buttons).to include(
        h.new_cluster_case_path(cluster_id: subject.id)
      )
    end

    it 'includes link to Cluster consultancy form' do
      expect(subject.case_form_buttons).to include(
        h.new_cluster_consultancy_path(cluster_id: subject.id)
      )
    end
  end
end
