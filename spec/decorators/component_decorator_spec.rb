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

  describe '#case_form_buttons' do
    subject { create(:component).decorate }

    include_examples 'case_form_buttons', 'component'

    it 'includes link to Component Case form' do
      expect(subject.case_form_buttons).to include(
        h.new_component_case_path(component_id: subject.id)
      )
    end

    it 'includes link to Component consultancy form' do
      expect(subject.case_form_buttons).to include(
        h.new_component_consultancy_path(component_id: subject.id)
      )
    end
  end
end
