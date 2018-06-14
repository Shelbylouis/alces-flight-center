require 'rails_helper'

RSpec.describe ProgressMaintenanceWindow do
  describe '#progress' do
    RSpec.shared_examples 'progresses' do |args|
      from = args[:from]
      to = args[:to]

      it "progresses #{from} window to #{to}" do
        window = test_progression(
          initial_state: from,
          expected_state: to,
          expected_message: "#{from} -> #{to}"
        )

        # Need to check that the transition model is created when the window is
        # created to avoid gotcha with `state_machines` Gem where implicit
        # transitions do not fire callbacks (see
        # https://github.com/state-machines/state_machines-activerecord/issues/47).
        corresponding_transitions =
          window.transitions.where(from: from, to: to)
        expect(corresponding_transitions.length).to eq 1
      end
    end

    RSpec.shared_examples 'does not progress' do |states|
      it "does not progress window in states: #{states.join(', ').strip}" do
        states.each do |state|
          test_progression(
            initial_state: state,
            expected_state: state,
            expected_message: "remains #{state}"
          )
        end
      end
    end

    RSpec.shared_examples 'progresses unstarted windows' do
      include_examples 'progresses', from: :confirmed, to: :started
      include_examples 'progresses', from: :new, to: :expired
      include_examples 'progresses', from: :requested, to: :expired
    end

    def build_window(state:)
      # Use `build` rather than `create` as many of the windows will be invalid
      # at the time they are created, as they are ready to be transitioned to a
      # different state and would now be invalid if they were saved in their
      # current state.
      build(
        :maintenance_window,
        state: state,
        requested_start: requested_start,
        duration: 1,
        component: component,
        id: 123
      )
    end

    def test_progression(initial_state:, expected_state:, expected_message:)
      window = build_window(state: initial_state)

      result = described_class.new(window).progress

      expect(window.state.to_sym).to eq expected_state
      test_progression_message(
        message: result,
        window: window,
        expected: expected_message
      )

      # Return window so any other needed assertions can be made on it.
      window
    end

    def test_progression_message(message:, window:, expected:)
      start_date = window.requested_start.to_formatted_s(:short)
      end_date = window.expected_end.to_formatted_s(:short)
      full_expected_message = <<~EOF.squish
        Maintenance window #{window.id} (#{component.name} | #{start_date} -
        #{end_date}): #{expected}
      EOF
      expect(message).to eq full_expected_message
    end

    let :component do
      create(:component, name: 'somenode')
    end

    context 'when requested_start and expected_end in future' do
      let(:requested_start) { 1.day.from_now }

      include_examples 'does not progress', MaintenanceWindow.possible_states
    end

    context 'when just requested_start passed' do
      let(:requested_start) { 1.hours.ago }

      include_examples 'progresses unstarted windows'

      other_states = MaintenanceWindow.possible_states - [:confirmed, :new, :requested]
      include_examples 'does not progress', other_states
    end

    context 'when requested_start and expected_end passed' do
      let(:requested_start) { 7.days.ago }

      # If both `requested_start` and `expected_end` have passed and a window
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

    describe 'maintenance is nearing completion' do
      let(:requested_start) { 23.hours.ago }

      context 'when maintenance has started' do
        let(:window) { build_window(state: :started) }

        it 'sends notifications that maintenance is ending soon' do
          expect(CaseMailer).to receive(:maintenance_ending_soon)

          described_class.new(window).progress
        end

        it 'does not send notifications if already sent' do
          window.update!(maintenance_ending_soon_email_sent: true)

          expect(CaseMailer).not_to receive(:maintenance_ending_soon)

          described_class.new(window).progress
        end
      end

      other_states = MaintenanceWindow.possible_states - [:started]
      other_states.each do |state|
        context "when state is '#{state}'" do
          it 'does not send notifications' do
            window = build_window(state: state)

            expect(CaseMailer).not_to receive(:maintenance_ending_soon)

            described_class.new(window).progress
          end
        end
      end
    end
  end
end
