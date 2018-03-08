require 'rails_helper'

RSpec.describe MaintenanceWindow, type: :model do
  describe '#valid?' do
    describe 'associated_model validations' do
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

    context 'after invalid transition' do
      subject { create(:maintenance_window) }

      before :each do
        subject.request!
      end

      it { is_expected.to be_invalid }
    end

    describe 'requested_start and requested_end validations' do
      it { is_expected.to validate_presence_of(:requested_start) }
      it { is_expected.to validate_presence_of(:requested_end) }
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
        user = create(:admin, name: 'some_user')

        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(
          id: subject.case.rt_ticket_id,
          text: /Request for maintenance of some_component cancelled by some_user/
        )

        subject.cancel!(user)
      end
    end

    RSpec.shared_examples 'can be expired' do
      it 'can be expired' do
        subject.expire!

        expect(subject).to be_expired
      end

      it 'has RT ticket comment added when expired' do
        subject.component = create(:component, name: 'some_component')

        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(
          id: subject.case.rt_ticket_id,
          text: /maintenance of some_component was not confirmed before requested start.*automatically cancelled/
        )

        subject.expire!
      end
    end

    context 'when new' do
      subject { create(:maintenance_window, state: :new) }

      include_examples 'can be cancelled'
      include_examples 'can be expired'

      it 'can be requested' do
        user = create(:user)
        subject.request!(user)

        expect(subject).to be_requested
      end

      it 'has RT ticket comment added when requested' do
        subject.component = create(:component, name: 'some_component')
        subject.requested_start = 1.days.since
        subject.requested_end = 2.days.since
        requestor = create(:admin, name: 'some_user')

        expected_start = subject.requested_start.to_formatted_s(:short)
        expected_end = subject.requested_end.to_formatted_s(:short)
        expected_cluster_url = Rails.application.routes.url_helpers.cluster_url(
          subject.component.cluster
        )
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(
          id: subject.case.rt_ticket_id,
          text: /requested.*some_component.*#{expected_start}.*#{expected_end}.*by some_user.*must be confirmed.*#{expected_cluster_url}/
        )

        subject.request!(requestor)
      end
    end

    context 'when requested' do
      subject { create(:maintenance_window, state: :requested) }

      include_examples 'can be cancelled'
      include_examples 'can be expired'

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
          text: /maintenance.*some_component.*confirmed by some_user.*scheduled/
        )

        subject.confirm!(user)
      end

      it 'can be rejected' do
        user = create(:user)
        subject.reject!(user)

        expect(subject).to be_rejected
      end

      it 'has RT ticket comment added when rejected' do
        subject.component = create(:component, name: 'some_component')
        user = create(:user, name: 'some_user')

        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(
          id: subject.case.rt_ticket_id,
          text: /maintenance.*some_component.*rejected by some_user/
        )

        subject.reject!(user)
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
          text: /maintenance of some_component .* started/
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
          text: /maintenance of some_component .* ended/
        )

        subject.end!
      end
    end

    it 'does not have transition comment added when `skip_comments` flag set on model' do
      # This test tests this behaviour for the started -> ended transition, but
      # any valid transition could be used.
      window = create(:maintenance_window, state: :started)
      window.skip_comments = true

      expect(Case.request_tracker).not_to receive(:add_ticket_correspondence)

      window.end!
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

  describe 'values tracked in transitions' do
    it 'tracks requested_start in transitions' do
      window = create(:maintenance_window, requested_start: 1.days.from_now)

      new_requested_start = 2.days.from_now.at_midnight
      window.requested_start = new_requested_start
      window.request!(create(:admin))

      request_transition = window.transitions.where(event: :request).first
      expect(request_transition.requested_start).to eq(new_requested_start)
    end

    it 'tracks requested_end in transitions' do
      window = create(:maintenance_window, requested_end: 1.days.from_now)

      new_requested_end = 2.days.from_now.at_midnight
      window.requested_end = new_requested_end
      window.request!(create(:admin))

      request_transition = window.transitions.where(event: :request).first
      expect(request_transition.requested_end).to eq(new_requested_end)
    end
  end

  describe '#method_missing' do
    describe '#*_at' do
      it 'returns time transition occurred for valid state' do
        maintenance_window = create(:maintenance_window)
        user = create(:admin)
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
        user = create(:admin, name: 'some_user')
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

  describe '#respond_to?' do
    subject { create(:maintenance_window) }

    # Examples of new methods it should respond to.
    it { is_expected.to respond_to(:requested_by) }
    it { is_expected.to respond_to(:confirmed_at) }

    # Methods from parents it should still respond to.
    it { is_expected.to respond_to(:created_at) }
    it { is_expected.to respond_to(:updated_at) }

    # Other examples of methods it shouldn't respond to.
    it { is_expected.not_to respond_to(:exploded_at) }
    it { is_expected.not_to respond_to(:exploded_by) }
    it { is_expected.not_to respond_to(:some_other_method) }
  end

  describe 'class' do
    subject { described_class }

    describe '#possible_states' do
      it 'gives all possible states' do
        expect(subject.possible_states).to match_array([
          :cancelled,
          :confirmed,
          :ended,
          :expired,
          :new,
          :rejected,
          :requested,
          :started,
        ])
      end
    end

    describe '#unfinished' do
      it 'returns all windows which have not reached a finished state' do
        subject.possible_states.each do |state|
          create(:maintenance_window, state: state)
        end

        unfinished_windows = described_class.unfinished

        unfinished_window_states = unfinished_windows.map(&:state).map(&:to_sym)
        expect(unfinished_window_states).to match_array([
          :confirmed,
          :new,
          :requested,
          :started,
        ])
      end
    end
  end
end
