require 'rails_helper'

RSpec.describe MaintenanceWindow, type: :model do
  it { is_expected.to validate_presence_of(:requested_start) }
  it { is_expected.to validate_presence_of(:requested_end) }

  describe '#valid?' do
    subject do
      build(
        :maintenance_window,
        cluster: cluster,
        component: component,
        service: service
      )
    end
    let :cluster { nil }
    let :component { nil }
    let :service { nil }

    context 'when single associated model given' do
      let :cluster { create(:cluster) }

      it { is_expected.to be_valid }
    end

    context 'when no associated model given' do
      it { is_expected.to be_invalid }
    end

    context 'when both Cluster and Component associated' do
      let :cluster { create(:cluster) }
      let :component { create(:component) }

      it { is_expected.to be_invalid }
    end

    context 'when both Cluster and Service associated' do
      let :cluster { create(:cluster) }
      let :service { create(:service) }

      it { is_expected.to be_invalid }
    end

    context 'when both Component and Service associated' do
      let :component { create(:component) }
      let :service { create(:service) }

      it { is_expected.to be_invalid }
    end
  end

  describe 'states' do
    it 'is initially in new state' do
      window = create(:maintenance_window)

      expect(window.state).to eq 'new'
    end

    RSpec.shared_examples 'can be cancelled' do
      it 'can be cancelled' do
        user = create(:user)
        subject.cancel!(user)

        expect(subject).to be_cancelled
      end

      it 'has RT ticket comment added when cancelled' do
        subject.component = create(:component, name: 'some_component')
        user = create(:user, name: 'some_user')

        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(
          id: subject.case.rt_ticket_id,
          text: /Request for maintenance of some_component cancelled by some_user/
        )

        subject.cancel!(user)
      end
    end

    context 'when new' do
      subject { create(:maintenance_window, state: :new) }

      include_examples 'can be cancelled'

      it 'can be requested' do
        user = create(:user)
        subject.request!(user)

        expect(subject).to be_requested
      end

      it 'has RT ticket comment added when requested' do
        subject.component = create(:component, name: 'some_component')
        requestor = create(:user, name: 'some_user')

        expected_cluster_url = Rails.application.routes.url_helpers.cluster_url(
          subject.component.cluster
        )
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(
          id: subject.case.rt_ticket_id,
          text: /requested.*some_component.*by some_user.*must be confirmed.*#{expected_cluster_url}/
        )

        subject.request!(requestor)
      end
    end

    context 'when requested' do
      subject { create(:maintenance_window, state: :requested) }

      include_examples 'can be cancelled'

      it 'can be confirmed by user' do
        user = create(:user)
        subject.confirm!(user)

        expect(subject).to be_confirmed
        expect(subject.confirmed_by).to eq(user)
      end

      it 'has RT ticket comment added when confirmed' do
        subject.component = create(:component, name: 'some_component')
        user = create(:user, name: 'some_user')

        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(
          id: subject.case.rt_ticket_id,
          text: /Maintenance.*some_component.*confirmed by some_user.*component.*now under maintenance/
        )

        subject.confirm!(user)
      end
    end

    context 'when confirmed' do
      subject do
        create(:maintenance_window, state: :confirmed)
      end

      it 'can be started' do
        subject.start!

        expect(subject).to be_started
      end

      it 'has RT ticket comment added when started' do
        subject.component = create(:component, name: 'some_component')

        expect(Case.request_tracker).to receive(:add_ticket_correspondence).with(
          id: subject.case.rt_ticket_id,
          text: "confirmed maintenance of some_component started."
        )

        subject.start!
      end
    end

    context 'when started' do
      subject do
        create(:maintenance_window, state: :started)
      end

      it 'can be ended' do
        subject.end!

        expect(subject).to be_ended
      end

      it 'has RT ticket comment added when ended' do
        subject.component = create(:component, name: 'some_component')

        expect(Case.request_tracker).to receive(:add_ticket_correspondence).with(
          id: subject.case.rt_ticket_id,
          text: "some_component is no longer under maintenance."
        )

        subject.end!
      end
    end
  end

  describe '#in_progress?' do
    it 'is currently an alias for `confirmed?`' do
      window = create(:confirmed_maintenance_window)

      expect(window).to be_in_progress
    end
  end

  describe '#associated_cluster' do
    it 'gives cluster when associated model is cluster' do
      cluster = create(:cluster)
      window = create(:maintenance_window, cluster: cluster)

      expect(window.associated_cluster).to eq(cluster)
    end

    it "gives associated model's cluster when associated model is not cluster" do
      component = create(:component)
      window = create(:maintenance_window, component: component)

      expect(window.associated_cluster).to eq(component.cluster)
    end
  end

  describe '#method_missing' do
    describe '#*_at' do
      it 'returns time transition occurred for valid state' do
        maintenance_window = create(:maintenance_window)
        user = create(:user)
        maintenance_window.request!(user)
        transition_time = 3.days.ago.at_midnight
        maintenance_window
          .transitions
          .where(to: :requested)
          .first
          .update!(created_at: transition_time)

        expect(maintenance_window.requested_at).to eq(transition_time)
      end

      it 'returns nil for valid state which has not occurred' do
        maintenance_window = create(:maintenance_window)

        expect(maintenance_window.expired_at).to be nil
      end

      it 'raises for invalid state' do
        maintenance_window = create(:maintenance_window)

        expect { maintenance_window.exploded_at }.to raise_error(NoMethodError)
      end
    end

    describe '#*_by' do
      it 'returns the user associated with transition for valid state' do
        user = create(:user, name: 'some_user')
        maintenance_window = create(:maintenance_window)
        maintenance_window.request!(user)

        expect(maintenance_window.requested_by).to eq user
      end

      it 'returns nil for valid state which has not occurred' do
        maintenance_window = create(:maintenance_window)

        expect(maintenance_window.rejected_by).to be nil
      end

      it 'returns nil for transition with no associated user saved' do
        maintenance_window = create(:maintenance_window, state: :confirmed)
        maintenance_window.start!

        expect(maintenance_window.started_by).to be nil
      end

      it 'raises for invalid state' do
        maintenance_window = create(:maintenance_window)

        expect { maintenance_window.exploded_by }.to raise_error(NoMethodError)
      end
    end

    it 'raises for unhandled methods' do
      maintenance_window = create(:maintenance_window)

      expect { maintenance_window.requested_foo }.to raise_error(NoMethodError)
    end
  end
end
