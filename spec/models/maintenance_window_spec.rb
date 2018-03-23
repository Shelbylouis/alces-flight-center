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

    RSpec.shared_examples 'it can be expired' do
      it 'can be expired' do
        subject.expire!

        expect(subject).to be_expired
      end

      it 'has RT ticket comment added when expired' do
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

        subject.expire!
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
        subject.requested_end = 2.days.since
        requestor = create(:admin, name: 'some_user')

        expected_start = subject.requested_start.to_formatted_s(:short)
        expected_end = subject.requested_end.to_formatted_s(:short)
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
        expected_end = subject.requested_end.to_formatted_s(:short)
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

    RSpec.shared_examples 'it can be started' do
      it 'can be started' do
        subject.start!

        expect(subject).to be_started
      end

      it 'has RT ticket comment added when started' do
        subject.component = create(:component, name: 'some_component')

        expected_end = subject.requested_end.to_formatted_s(:short)
        text_regex = Regexp.new <<~REGEX.squish
          maintenance of some_component .* started.*this component.*under
          maintenance until #{expected_end}
        REGEX
        expect(Case.request_tracker).to receive(
          :add_ticket_correspondence
        ).with(id: subject.case.rt_ticket_id, text: text_regex)

        subject.start!
      end
    end

    RSpec.shared_examples 'it can be ended' do
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

    context 'when new' do
      subject { create(:maintenance_window, state: :new) }

      it_behaves_like 'it can be cancelled'
      it_behaves_like 'it can be expired'
      it_behaves_like 'it can be requested'
    end

    context 'when requested' do
      subject { create(:maintenance_window, state: :requested) }

      it_behaves_like 'it can be cancelled'
      it_behaves_like 'it can be expired'
      it_behaves_like 'it can be confirmed'
      it_behaves_like 'it can be rejected'
    end

    context 'when confirmed' do
      subject do
        create(:maintenance_window, state: :confirmed)
      end

      it_behaves_like 'it can be started'
    end

    context 'when started' do
      subject do
        create(:maintenance_window, state: :started)
      end

      it_behaves_like 'it can be ended'
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

  describe '#expected_end' do
    let :monday { DateTime.new(2025, 3, 24, 9, 0) }
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
          :expired,
        ])
      end
    end
  end
end
