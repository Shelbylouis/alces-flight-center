require 'rails_helper'

RSpec.describe MaintenanceWindowStateTransition, type: :model do
  describe '#valid?' do
    describe 'user' do

      RSpec.shared_examples 'it must be initiated by a site contact' do
        it 'cannot be initiated by admin' do
          subject.user = create(:admin)

          expect(subject).not_to be_valid
          expect(subject.errors.messages).to include user: [/must be a site contact/]
        end

        it 'can be initiated by contact' do
          subject.user = create(:contact)

          expect(subject).to be_valid
        end
      end

      subject do
        build(:maintenance_window_state_transition, event: event, user: user)
      end

      admin_only_events = [:request, :mandate, :cancel, :extend_duration, :end]
      contact_only_events = [:reject]
      any_user_initiated_events = [:confirm]
      automatic_events = [:auto_start, :auto_end, :auto_expire, nil]

      it 'tests cover all possible events' do
        covered_events = [
          admin_only_events,
          contact_only_events,
          any_user_initiated_events,
          automatic_events
        ].flatten

        # `nil` must be handled as a `nil` event will occur for the initial
        # transition (from `nil` to `:new`) automatically created when a
        # MaintenanceWindow is created.
        expect(covered_events).to match_array MaintenanceWindow.events + [nil]
      end

      admin_only_events.each do |event|
        context "when `#{event}` event" do
          let(:event) { event }
          let(:user) { create(:admin) }

          it_behaves_like 'it must be initiated by an admin'
          it { is_expected.to validate_presence_of(:user) }
        end
      end

      contact_only_events.each do |event|
        context "when `#{event}` event" do
          let(:event) { event }
          let(:user) { create(:contact) }

          it_behaves_like 'it must be initiated by a site contact'
          it { is_expected.to validate_presence_of(:user) }
        end
      end

      any_user_initiated_events.each do |event|
        context "when `#{event}` event" do
          let(:event) { event }
          let(:user) { create(:user) }

          it { is_expected.to validate_presence_of(:user) }
        end
      end

      automatic_events.each do |event|
        context "when `#{event}` event" do
          let(:event) { event }
          let(:user) { nil }

          it { is_expected.to validate_absence_of(:user) }
        end
      end
    end
  end
end
