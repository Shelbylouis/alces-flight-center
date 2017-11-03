require 'rails_helper'

RSpec.describe CaseDecorator do
  describe '#association_info' do
    context 'when Case has Component' do
      subject do
        create(:case_with_component).decorate
      end

      let :component { subject.component }

      it 'returns link to Component' do
        expect(
          subject.association_info
        ).to eq(
          h.link_to(component.name, h.component_path(component))
        )
      end
    end

    context 'when Case has Service' do
      subject do
        create(:case_with_service).decorate
      end

      let :service { subject.service }

      it 'returns link to Service' do
        expect(
          subject.association_info
        ).to eq(
          h.link_to(service.name, h.service_path(service))
        )
      end
    end

    context 'when Case has no Component or Service' do
      subject do
        create(:case).decorate
      end

      it 'returns N/A' do
        expect(
          subject.association_info
        ).to eq(
          h.raw('<em>N/A</em>')
        )
      end
    end
  end
end
