require 'rails_helper'

RSpec.describe CaseDecorator do
  # XXX Parts of these tests and corresponding code duplicated and adapted for
  # {Cluster,Component,Service}Decorator.
  describe '#association_info' do
    let :cluster { subject.cluster }

    context 'when Case has Component' do
      subject do
        create(:case_with_component).decorate
      end

      let :component { subject.component }

      it 'includes link to Component' do
        expect(
          subject.association_info
        ).to include(
          h.link_to(component.name, h.component_path(component))
        )
      end

      it 'includes link to Cluster' do
        expect(
          subject.association_info
        ).to include(
          h.link_to(cluster.name, h.cluster_path(cluster))
        )
      end
    end

    context 'when Case has Service' do
      subject do
        create(:case_with_service).decorate
      end

      let :service { subject.service }

      it 'includes link to Service' do
        expect(
          subject.association_info
        ).to include(
          h.link_to(service.name, h.service_path(service))
        )
      end

      # XXX Same as test for Component.
      it 'includes link to Cluster' do
        expect(
          subject.association_info
        ).to include(
          h.link_to(cluster.name, h.cluster_path(cluster))
        )
      end
    end

    context 'when Case has no Component or Service' do
      subject do
        create(:case).decorate
      end

      it 'returns link to Cluster' do
        expect(
          subject.association_info
        ).to eq(
          h.link_to(cluster.name, h.cluster_path(cluster))
        )
      end
    end
  end
end
