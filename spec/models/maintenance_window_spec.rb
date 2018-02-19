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

    context 'when new' do
      subject { create(:maintenance_window, state: :new) }

      it { is_expected.to validate_absence_of(:confirmed_at) }
      it { is_expected.to validate_absence_of(:confirmed_by) }

      it { is_expected.to validate_absence_of(:ended_at) }

      it { is_expected.to validate_absence_of(:rejected_at) }
      it { is_expected.to validate_absence_of(:rejected_by) }

      it { is_expected.to validate_absence_of(:cancelled_at) }
      it { is_expected.to validate_absence_of(:cancelled_by) }

      it { is_expected.to validate_absence_of(:expired_at) }

      it 'can be requested' do
        subject.request!

        expect(subject).to be_requested
      end

      it 'has RT ticket comment added when requested' do
        subject.component = create(:component, name: 'some_component')
        subject.requested_by = create(:user, name: 'some_user')

        expected_cluster_url = Rails.application.routes.url_helpers.cluster_url(
          subject.component.cluster
        )
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(
          id: subject.case.rt_ticket_id,
          text: /requested.*some_component.*by some_user.*must be confirmed.*#{expected_cluster_url}/
        )

        subject.request!
      end
    end

    context 'when requested' do
      subject { create(:maintenance_window, state: :requested) }

      it { is_expected.to validate_absence_of(:confirmed_at) }
      it { is_expected.to validate_absence_of(:confirmed_by) }

      it { is_expected.to validate_absence_of(:ended_at) }

      it { is_expected.to validate_absence_of(:rejected_at) }
      it { is_expected.to validate_absence_of(:rejected_by) }

      it { is_expected.to validate_absence_of(:cancelled_at) }
      it { is_expected.to validate_absence_of(:cancelled_by) }

      it { is_expected.to validate_absence_of(:expired_at) }

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
        create(
          :maintenance_window,
          state: :confirmed,
          confirmed_at: DateTime.current,
          confirmed_by: create(:user),
        )
      end

      it { is_expected.to validate_presence_of(:confirmed_at) }
      it { is_expected.to validate_presence_of(:confirmed_by) }

      it { is_expected.to validate_absence_of(:ended_at) }

      it { is_expected.to validate_absence_of(:rejected_at) }
      it { is_expected.to validate_absence_of(:rejected_by) }

      it { is_expected.to validate_absence_of(:cancelled_at) }
      it { is_expected.to validate_absence_of(:cancelled_by) }

      it { is_expected.to validate_absence_of(:expired_at) }

      it 'can be started' do
        now = DateTime.current
        allow(DateTime).to receive(:current).and_return(now)

        subject.start!

        expect(subject.started_at).to eq now
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
        create(
          :maintenance_window,
          state: :started,
          confirmed_at: DateTime.current,
          confirmed_by: create(:user),
          started_at: DateTime.current,
        )
      end

      it { is_expected.to validate_presence_of(:confirmed_at) }
      it { is_expected.to validate_presence_of(:confirmed_by) }

      it { is_expected.to validate_absence_of(:ended_at) }

      it { is_expected.to validate_absence_of(:rejected_at) }
      it { is_expected.to validate_absence_of(:rejected_by) }

      it { is_expected.to validate_absence_of(:cancelled_at) }
      it { is_expected.to validate_absence_of(:cancelled_by) }

      it { is_expected.to validate_absence_of(:expired_at) }

      it 'can be ended' do
        now = DateTime.current
        allow(DateTime).to receive(:current).and_return(now)

        subject.end!

        expect(subject).to be_ended
        expect(subject.ended_at).to eq now
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

    context 'when ended' do
      subject do
        create(
          :maintenance_window,
          state: :ended,
          confirmed_at: DateTime.current,
          confirmed_by: create(:user),
          ended_at: DateTime.current
        )
      end

      it { is_expected.to validate_presence_of(:confirmed_at) }
      it { is_expected.to validate_presence_of(:confirmed_by) }

      it { is_expected.to validate_presence_of(:ended_at) }

      it { is_expected.to validate_absence_of(:rejected_at) }
      it { is_expected.to validate_absence_of(:rejected_by) }

      it { is_expected.to validate_absence_of(:cancelled_at) }
      it { is_expected.to validate_absence_of(:cancelled_by) }

      it { is_expected.to validate_absence_of(:expired_at) }
    end

    context 'when rejected' do
      subject do
        create(
          :maintenance_window,
          state: :rejected,
          rejected_by: create(:user),
          rejected_at: DateTime.current
        )
      end

      it { is_expected.to validate_absence_of(:confirmed_at) }
      it { is_expected.to validate_absence_of(:confirmed_by) }

      it { is_expected.to validate_absence_of(:ended_at) }

      it { is_expected.to validate_presence_of(:rejected_at) }
      it { is_expected.to validate_presence_of(:rejected_by) }

      it { is_expected.to validate_absence_of(:cancelled_at) }
      it { is_expected.to validate_absence_of(:cancelled_by) }

      it { is_expected.to validate_absence_of(:expired_at) }
    end

    context 'when cancelled' do
      subject do
        create(
          :maintenance_window,
          state: :cancelled,
          cancelled_by: create(:user),
          cancelled_at: DateTime.current
        )
      end

      it { is_expected.to validate_absence_of(:ended_at) }

      it { is_expected.to validate_absence_of(:rejected_at) }
      it { is_expected.to validate_absence_of(:rejected_by) }

      it { is_expected.to validate_presence_of(:cancelled_at) }
      it { is_expected.to validate_presence_of(:cancelled_by) }

      it { is_expected.to validate_absence_of(:expired_at) }
    end

    context 'when expired' do
      subject do
        create(
          :maintenance_window,
          state: :expired,
          expired_at: DateTime.current
        )
      end

      it { is_expected.to validate_absence_of(:confirmed_at) }
      it { is_expected.to validate_absence_of(:confirmed_by) }

      it { is_expected.to validate_absence_of(:ended_at) }

      it { is_expected.to validate_absence_of(:rejected_at) }
      it { is_expected.to validate_absence_of(:rejected_by) }

      it { is_expected.to validate_absence_of(:cancelled_at) }
      it { is_expected.to validate_absence_of(:cancelled_by) }

      it { is_expected.to validate_presence_of(:expired_at) }
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
end
