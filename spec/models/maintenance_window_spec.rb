require 'rails_helper'

RSpec.describe MaintenanceWindow, type: :model do
  describe 'states' do
    it 'is initially in new state' do
      window = create(:maintenance_window)

      expect(window.state).to eq 'new'
    end

    RSpec.shared_examples 'it can be cancelled' do
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

    RSpec.shared_examples 'it can be auto-expired' do
      it 'can be auto-expired' do
        subject.auto_expire!

        expect(subject).to be_expired
      end

      it 'has RT ticket comment added when auto-expired' do
        subject.component = create(:component, name: 'some_component')

        expected_start = subject.requested_start.to_formatted_s(:short)
        expected_cluster_dashboard_url =
          Rails.application.routes.url_helpers.cluster_maintenance_windows_url(
            subject.component.cluster
        )
        text_regex = Regexp.new <<~REGEX.squish
          maintenance of some_component was not confirmed before requested
          start.*#{expected_start}.*rescheduled.*confirmed.*#{expected_cluster_dashboard_url}
        REGEX
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(id: subject.case.rt_ticket_id, text: text_regex)

        subject.auto_expire!
      end
    end

    RSpec.shared_examples 'it can be requested' do
      it 'can be requested' do
        user = create(:user)
        subject.request!(user)

        expect(subject).to be_requested
      end

      it 'has RT ticket comment added when requested' do
        subject.component = create(:component, name: 'some_component')
        subject.requested_start = 1.days.since
        requestor = create(:admin, name: 'some_user')

        expected_start = subject.requested_start.to_formatted_s(:short)
        expected_end = subject.expected_end.to_formatted_s(:short)
        expected_cluster_dashboard_url =
          Rails.application.routes.url_helpers.cluster_maintenance_windows_url(
            subject.component.cluster
        )
        text_regex = Regexp.new <<~REGEX.squish
          requested.*some_component.*#{expected_start}.*#{expected_end}.*by
          some_user.*must be confirmed.*#{expected_cluster_dashboard_url}
        REGEX
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with( id: subject.case.rt_ticket_id, text: text_regex)

        subject.request!(requestor)
      end
    end

    RSpec.shared_examples 'it can be confirmed' do
      it 'can be confirmed by user' do
        user = create(:user)
        subject.confirm!(user)

        expect(subject).to be_confirmed
        expect(subject.confirmed_by).to eq(user)
      end

      it 'has RT ticket comment added when confirmed' do
        subject.component = create(:component, name: 'some_component')
        user = create(:user, name: 'some_user')

        expected_start = subject.requested_start.to_formatted_s(:short)
        expected_end = subject.expected_end.to_formatted_s(:short)
        text_regex = Regexp.new <<~REGEX.squish
          maintenance.*some_component.*confirmed by
          some_user.*scheduled.*#{expected_start}.*#{expected_end}
        REGEX
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(id: subject.case.rt_ticket_id, text: text_regex)

        subject.confirm!(user)
      end
    end

    RSpec.shared_examples 'it can be mandated' do
      it 'can be mandated' do
        user = create(:admin)
        subject.mandate!(user)

        expect(subject).to be_confirmed
        expect(subject.confirmed_by).to eq user
      end

      it 'has RT ticket added when mandated' do
        subject.component = create(:component, name: 'some_component')
        user = create(:admin, name: 'some_admin')

        expected_start = subject.requested_start.to_formatted_s(:short)
        expected_end = subject.expected_end.to_formatted_s(:short)
        text_regex = Regexp.new <<~EOF.squish
          Maintenance.*some_component.*scheduled.*from #{expected_start} until
          #{expected_end} by.*some_admin.*mandatory
        EOF
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(id: subject.case.rt_ticket_id, text: text_regex)

        subject.mandate!(user)
      end
    end

    RSpec.shared_examples 'it can be rejected' do
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

    RSpec.shared_examples 'it can be auto-started' do
      it 'can be auto-started' do
        subject.auto_start!

        expect(subject).to be_started
      end

      it 'has RT ticket comment added when auto-started' do
        subject.component = create(:component, name: 'some_component')

        expected_end = subject.expected_end.to_formatted_s(:short)
        text_regex = Regexp.new <<~REGEX.squish
          maintenance of some_component .* started.*this component.*under
          maintenance until #{expected_end}
        REGEX
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(id: subject.case.rt_ticket_id, text: text_regex)

        subject.auto_start!
      end
    end

    RSpec.shared_examples 'it can be extended' do |current_state|
      it 'can be extended' do
        original_state = subject.state
        admin = create(:admin)

        # Note: this event cannot just be called `extend` as this would clash
        # with `Object#extend`.
        subject.extend_duration!(admin)

        expect(subject.state).to eq(original_state)
      end

      it 'has RT ticket comment added when auto-started' do
        subject.component = create(:component, name: 'some_component')
        subject.duration = 5

        expected_start = subject.requested_start.to_formatted_s(:short)
        expected_end = subject.expected_end.to_formatted_s(:short)
        text_regex = Regexp.new <<~REGEX.squish
          #{current_state.capitalize} maintenance of some_component .*
          extended.*this component.*under maintenance from #{expected_start}
          until #{expected_end}
        REGEX
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(id: subject.case.rt_ticket_id, text: text_regex)

        subject.extend_duration!(create(:admin))
      end
    end

    RSpec.shared_examples 'it can be auto-ended' do
      it 'can be auto-ended' do
        subject.auto_end!

        expect(subject).to be_ended
      end

      it 'has RT ticket comment added when auto-ended' do
        subject.component = create(:component, name: 'some_component')

        expect(Case.request_tracker).to receive(:add_ticket_correspondence).with(
          id: subject.case.rt_ticket_id,
          text: /maintenance of some_component .* ended/
        )

        subject.auto_end!
      end
    end

    RSpec.shared_examples 'it can be ended' do
      it 'can be ended' do
        admin = create(:admin)
        subject.end!(admin)

        expect(subject).to be_ended
        expect(subject.ended_by).to eq admin
      end

      it 'has RT ticket comment added when ended' do
        admin = create(:admin, name: 'some_admin')
        subject.component = create(:component, name: 'some_component')

        expect(Case.request_tracker).to receive(:add_ticket_correspondence).with(
          id: subject.case.rt_ticket_id,
          text: /maintenance of some_component ended by some_admin/i
        )

        subject.end!(admin)
      end
    end

    context 'when new' do
      subject { create(:maintenance_window, state: :new) }

      it_behaves_like 'it can be cancelled'
      it_behaves_like 'it can be auto-expired'
      it_behaves_like 'it can be requested'
      it_behaves_like 'it can be mandated'
    end

    context 'when requested' do
      subject { create(:maintenance_window, state: :requested) }

      it_behaves_like 'it can be cancelled'
      it_behaves_like 'it can be auto-expired'
      it_behaves_like 'it can be confirmed'
      it_behaves_like 'it can be rejected'
    end

    context 'when confirmed' do
      subject do
        create(:maintenance_window, state: :confirmed)
      end

      it_behaves_like 'it can be auto-started'
      it_behaves_like 'it can be extended', 'scheduled'
    end

    context 'when started' do
      subject do
        create(:maintenance_window, state: :started)
      end

      it_behaves_like 'it can be ended'
      it_behaves_like 'it can be auto-ended'
      it_behaves_like 'it can be extended', 'ongoing'
    end

    context 'when expired' do
      subject do
        create(:maintenance_window, state: :expired)
      end

      it_behaves_like 'it can be cancelled'
      it_behaves_like 'it can be confirmed'
      it_behaves_like 'it can be rejected'
    end

    it 'does not have transition comment added when `legacy_migration_mode` flag set on model' do
      # This test tests this behaviour for the started -> ended transition, but
      # any valid transition could be used.
      window = create(:maintenance_window, state: :started)
      window.legacy_migration_mode = true

      expect(Case.request_tracker).not_to receive(:add_ticket_correspondence)

      window.auto_end!
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

    it 'tracks duration in transitions' do
      window = create(:maintenance_window, duration: 1)

      new_duration = 2
      window.duration = new_duration
      window.request!(create(:admin))

      request_transition = window.transitions.where(event: :request).first
      expect(request_transition.duration).to eq(new_duration)
    end
  end

  describe '#expected_end' do
    let :monday { Time.zone.local(2025, 3, 24, 9, 0) }
    let :wednesday { monday.advance(days: 2) }
    let :following_monday { monday.advance(weeks: 1) }

    it 'gives expected end date calculated from requested_start and duration' do
      window = create(
        :maintenance_window,
        requested_start: monday,
        duration: 2
      )

      expect(window.expected_end).to eq(wednesday)
    end

    it 'only includes business days in calculation' do
      window = create(
        :maintenance_window,
        requested_start: monday,
        duration: 5
      )

      expect(window.expected_end).to eq(following_monday)
    end
  end

  describe '#user_facing_state' do
    it 'handles all possible states' do
      MaintenanceWindow.possible_states.each do |state|
        window = create(:maintenance_window, state: state)

        expect(window.user_facing_state).to be_a(String)
      end
    end

    [:new, :requested, :expired].each do |state|
      it "gives 'requested' for `#{state}` maintenance" do
        window = create(:maintenance_window, state: state)

        expect(window.user_facing_state).to eq('requested')
      end
    end

    it "gives 'scheduled' for `confirmed` maintenance" do
      window = create(:maintenance_window, state: :confirmed)

      expect(window.user_facing_state).to eq('scheduled')
    end

    it "gives 'ongoing' for `started` maintenance" do
      window = create(:maintenance_window, state: 'started')

      expect(window.user_facing_state).to eq('ongoing')
    end

    [:ended, :rejected, :cancelled].each do |state|
      it "gives 'finished' for `#{state}` maintenance" do
        window = create(:maintenance_window, state: state)

        expect(window.user_facing_state).to eq('finished')
      end
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
        maintenance_window.auto_start!

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

    describe '#events' do
      it 'gives all possible events' do
        expect(subject.events).to match_array([
          :auto_end,
          :auto_expire,
          :auto_start,
          :cancel,
          :confirm,
          :end,
          :extend_duration,
          :mandate,
          :reject,
          :request,
        ])
      end
    end

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
          :expired,
        ])
      end
    end
  end
end
