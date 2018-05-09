require 'rails_helper'

RSpec.describe ComponentDecorator do
  describe '#links' do
    subject { create(:component).decorate }

    it 'includes link to Component' do
      expect(
        subject.links
      ).to include(
        h.link_to(subject.name, h.component_path(subject))
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
end
