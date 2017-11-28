require 'rails_helper'

RSpec.describe ApplicationDecorator do
  describe '#start_maintenance_request_link' do
    subject { component.decorate.start_maintenance_request_link }
    let :component { create(:component) }

    before :each do
      allow(h).to receive(:current_user).and_return(user)
    end

    context 'when admin' do
      let :user { create(:admin) }

      it 'gives link to request maintenance page for object' do
        expect(subject).to eq(
          h.link_to h.raw(h.icon 'wrench', interactive: true),
          h.new_component_maintenance_window_path(component),
          title: 'Start request for maintenance of this component'
        )
      end
    end

    context 'when contact' do
      let :user { create(:contact) }

      it { is_expected.to be nil }
    end
  end
end
