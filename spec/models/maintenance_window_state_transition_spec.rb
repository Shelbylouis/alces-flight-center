require 'rails_helper'

RSpec.describe MaintenanceWindowStateTransition, type: :model do
  describe '#valid?' do
    describe 'user' do
      RSpec.shared_examples 'it must be initiated by an admin' do
        it 'can be initiated by admin' do
          subject.user = create(:admin)

          expect(subject).to be_valid
        end

        it 'cannot be initiated by contact' do
          subject.user = create(:contact)

          expect(subject).not_to be_valid
          expect(subject.errors.messages).to include user: [/must be an admin/]
        end
      end

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

      admin_only_events = [:request, :mandate, :cancel]
      contact_only_events = [:reject]
      any_user_initiated_events = [:confirm]
      automatic_events = [:start, :end, :expire, nil]

      admin_only_events.each do |event|
        context "when `#{event}` event" do
          subject do
            build(
              :maintenance_window_state_transition,
              event: event,
              user: create(:admin),
            )
          end

          it_behaves_like 'it must be initiated by an admin'
          it { is_expected.to validate_presence_of(:user) }
        end
      end

      contact_only_events.each do |event|
        context "when `#{event}` event" do
          subject do
            build(
              :maintenance_window_state_transition,
              event: event,
              user: create(:contact),
            )
          end

          it_behaves_like 'it must be initiated by a site contact'
          it { is_expected.to validate_presence_of(:user) }
        end
      end

      any_user_initiated_events.each do |event|
        context "when `#{event}` event" do
          subject do
            build(
              :maintenance_window_state_transition,
              event: event,
              user: create(:user),
            )
          end

          it { is_expected.to validate_presence_of(:user) }
        end
      end

      automatic_events.each do |event|
        context "when `#{event}` event" do
          subject do
            build(:maintenance_window_state_transition, event: event)
          end

          it { is_expected.to validate_absence_of(:user) }
        end
      end
    end
  end
end
