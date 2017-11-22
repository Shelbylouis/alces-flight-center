require 'rails_helper'

RSpec.describe CaseDecorator do
  shared_examples 'indicate under maintenance' do |model_name|
    context 'when Case is under maintenance' do
      before :each do
        subject.start_maintenance_window!(requestor: create(:admin))
      end

      it 'includes under maintenance icon' do
        expect(subject.association_info).to include(
          h.icon('wrench', inline: true)
        )
      end

      it 'includes title text about maintenance' do
        expect(subject.association_info).to match(
          /title="#{model_name}.*under maintenance.*Case"/
        )
      end
    end
  end

  describe '#association_info' do
    context 'when Case has Component' do
      subject do
        create(:case_with_component).decorate
      end

      let :component { subject.component }

      include_examples 'indicate under maintenance', 'Component'

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
