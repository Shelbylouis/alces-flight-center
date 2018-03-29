require 'rails_helper'

RSpec.describe MaintenanceWindowStateTransition, type: :model do
  describe '#valid?' do
    describe 'user presence' do
      user_initiated_states = [:requested, :confirmed, :rejected, :cancelled]
      automatic_states = [:new, :started, :ended, :expired]

      user_initiated_states.each do |state|
        context "when transition to `#{state}`" do
          subject do
            build(:maintenance_window_state_transition, to: state)
          end

          it { is_expected.to validate_presence_of(:user) }
        end
      end

      automatic_states.each do |state|
        context "when transition to `#{state}`" do
          subject do
            build(:maintenance_window_state_transition, to: state)
          end

          it { is_expected.to validate_absence_of(:user) }
        end
      end
    end

    describe 'user type' do
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

      [:request, :mandate, :cancel].each do |event|
        context "when `#{event}` event" do
          subject do
            build(:maintenance_window_state_transition, event: event)
          end

          it_behaves_like 'it must be initiated by an admin'
        end
      end

      context 'when `reject` event' do
        subject do
          build(:maintenance_window_state_transition, event: :reject)
        end

        it_behaves_like 'it must be initiated by a site contact'
      end
    end
  end
end
