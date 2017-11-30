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

  describe '#maintenance_icons' do
    subject { component.decorate.maintenance_icons }
    let :component { create(:component, name: 'mycomponent') }

    it 'includes correct icon when has unconfirmed maintenance window' do
      create(:unconfirmed_maintenance_window, component: component)

      expect(subject).to include(
        h.icon(
          'wrench',
          inline: true,
          class: 'faded-icon',
          title: "Maintenance has been requested for #{component.name}"
        )
      )
    end

    it 'includes correct icon when has confirmed maintenance window' do
      create(:confirmed_maintenance_window, component: component)

      expect(subject).to include(
        h.icon(
          'wrench',
          inline: true,
          title: "#{component.name} currently under maintenance"
        )
      )
    end

    it 'gives nothing when no maintenance windows' do
      expect(subject).to be_empty
    end

    it 'gives nothing when only has closed maintenance window' do
      create(:closed_maintenance_window, component: component)
      expect(subject).to be_empty
    end

    it 'includes icon for every open maintenance window' do
      create(:unconfirmed_maintenance_window, component: component)
      create(:confirmed_maintenance_window, component: component)
      create(:closed_maintenance_window, component: component)

      expect(subject).to match(/<i .*<i /)
    end
  end
end
