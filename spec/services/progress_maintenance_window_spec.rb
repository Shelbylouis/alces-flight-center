require 'rails_helper'

RSpec.describe ProgressMaintenanceWindow do
  describe '#progress' do
    RSpec.shared_examples 'progresses unstarted windows' do
      it 'progresses confirmed window to started' do
        window = create_window(state: :confirmed)

        described_class.new(window).progress

        expect(window).to be_started
      end

      it 'progresses new window to expired' do
        window = create_window(state: :new)

        described_class.new(window).progress

        expect(window).to be_expired
      end

      it 'progresses requested window to expired' do
        window = create_window(state: :requested)

        described_class.new(window).progress

        expect(window).to be_expired
      end
    end

    context 'when requested_start and requested_end in future' do
      it 'does not progress window in any state' do
        MaintenanceWindow.possible_states.each do |state|
          window = create(
            :maintenance_window,
            state: state,
            requested_start: DateTime.current.advance(days: 1),
            requested_end: DateTime.current.advance(days: 2),
          )

          described_class.new(window).progress

          expect(window.state.to_sym).to eq state
        end
      end
    end

    context 'when just requested_start passed' do
      def create_window(state:)
        create(
          :maintenance_window,
          state: state,
          requested_start: 1.hours.ago,
          requested_end: DateTime.current.advance(days: 1)
        )
      end

      include_examples 'progresses unstarted windows'

      it 'does not progress window in other states' do
        other_states = MaintenanceWindow.possible_states - [:confirmed, :new, :requested]

        other_states.each do |state|
          window = create_window(state: state)

          described_class.new(window).progress

          expect(window.state.to_sym).to eq state
        end
      end
    end

    context 'when requested_start and requested_end passed' do
      def create_window(state:)
        create(
          :maintenance_window,
          state: state,
          requested_start: 2.hours.ago,
          requested_end: 1.hours.ago
        )
      end

      # If both `requested_start` and `requested_end` have passed and a window
      # has still not transitioned from an unstarted state (e.g. if the
      # maintenance period is very short or we have not progressed
      # MaintenanceWindows for a while for some reason), then we still want to
      # ensure the window is appropriately transitioned out of the unstarted
      # state so that any actions which should occur when this happens do still
      # occur. The window will still be ended if needed soon enough, as soon as
      # we next progress MaintenanceWindows.
      include_examples 'progresses unstarted windows'

      it 'progresses started window to ended' do
        window = create_window(state: :started)

        described_class.new(window).progress

        expect(window).to be_ended
      end

      it 'does not progress window in other states' do
        other_states = MaintenanceWindow.possible_states - [:started, :confirmed, :new, :requested]

        other_states.each do |state|
          window = create_window(state: state)

          described_class.new(window).progress

          expect(window.state.to_sym).to eq state
        end
      end
    end
  end
end
