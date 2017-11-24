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
end
