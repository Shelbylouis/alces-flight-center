require 'rails_helper'

RSpec.describe ProgressMaintenanceWindow do
  describe '#progress' do
    RSpec.shared_examples 'progresses' do |args|
      from = args[:from]
      to = args[:to]

      it "progresses #{from} window to #{to}" do
        window = create_window(state: from)

        described_class.new(window).progress

        expect(window.state.to_sym).to eq(to)
      end
    end

    RSpec.shared_examples 'does not progress' do |states|
      it "does not progress window in states: #{states.join(', ').strip}" do
        states.each do |state|
          window = create_window(state: state)

          described_class.new(window).progress

          expect(window.state.to_sym).to eq state
        end
      end
    end

    RSpec.shared_examples 'progresses unstarted windows' do
      include_examples 'progresses', from: :confirmed, to: :started
      include_examples 'progresses', from: :new, to: :expired
      include_examples 'progresses', from: :requested, to: :expired
    end

    context 'when requested_start and requested_end in future' do
      def create_window(state:)
        create(
          :maintenance_window,
          state: state,
          requested_start: DateTime.current.advance(days: 1),
          requested_end: DateTime.current.advance(days: 2),
        )
      end

      include_examples 'does not progress', MaintenanceWindow.possible_states
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

      other_states = MaintenanceWindow.possible_states - [:confirmed, :new, :requested]
      include_examples 'does not progress', other_states
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

      include_examples 'progresses', from: :started, to: :ended

      other_states = MaintenanceWindow.possible_states - [:started, :confirmed, :new, :requested]
      include_examples 'does not progress', other_states
    end
  end
end
