require 'rails_helper'

RSpec.describe ApplicationDecorator do
  describe '#start_maintenance_request_link' do
    subject { component.decorate.start_maintenance_request_link }
    let(:component) { create(:component) }

    before :each do
      allow(h).to receive(:current_user).and_return(user)
    end

    context 'when admin' do
      let(:user) { create(:admin) }

      it 'gives link to request maintenance page for object' do
        expect(subject).to eq(
          h.link_to h.raw(h.icon 'wrench', interactive: true),
          h.new_component_maintenance_window_path(component),
          title: 'Start request for maintenance of this component'
        )
      end
    end

    context 'when contact' do
      let(:user) { create(:contact) }

      it { is_expected.to be nil }
    end
  end

  describe '#cluster_part_icons' do
    describe 'maintenance icons' do
      subject { component.decorate.cluster_part_icons }
      let(:component) { create(:component, name: 'mycomponent') }

      it 'includes correct icon when has requested maintenance window' do
        window = create(:requested_maintenance_window, component: component)
        display_id = window.case.display_id

        expect(subject).to include(
          h.icon(
            'wrench',
            inline: true,
            class: 'faded-icon',
            title: "Maintenance has been requested for #{component.name} for case #{display_id}"
          )
        )
      end

      it 'includes correct icon when has confirmed maintenance window' do
        window = create(:confirmed_maintenance_window, component: component)
        display_id = window.case.display_id

        expect(subject).to include(
          h.icon(
            'wrench',
            inline: true,
            class: 'faded-icon',
            title: "Maintenance is scheduled for #{component.name} for case #{display_id}"
          )
        )
      end

      it 'includes correct icon when has in progress maintenance window' do
        window = create(:maintenance_window, state: :started, component: component)
        display_id = window.case.display_id

        expect(subject).to include(
          h.icon(
            'wrench',
            inline: true,
            title: "#{component.name} currently under maintenance for case #{display_id}"
          )
        )
      end

      it 'gives nothing when no maintenance windows' do
        expect(subject).to be_empty
      end

      it 'gives nothing when only has finished maintenance window' do
        create(:ended_maintenance_window, component: component)
        expect(subject).to be_empty
      end

      it 'includes icon for every unfinished maintenance window' do
        create(:requested_maintenance_window, component: component)
        create(:maintenance_window, state: :started, component: component)
        create(:ended_maintenance_window, component: component)

        expect(subject).to match(/<i .*<i /)
      end
    end

    describe 'internal icon' do
      it 'includes internal icon when internal' do
        part = create(:service, internal: true)

        expect(part.decorate.cluster_part_icons).to include(
          h.image_tag(
            'flight-icon',
            alt: 'Service for internal Alces usage',
            title: 'Service for internal Alces usage'
          )
        )
      end

      it 'does not include internal icon when not internal' do
        part = create(:component, internal: false)

        expect(part.decorate.cluster_part_icons).to be_empty
      end

      it 'does not include internal icon when does not have internal field' do
        cluster = create(:cluster)

        expect(cluster.decorate.cluster_part_icons).to be_empty
      end
    end
  end
end
