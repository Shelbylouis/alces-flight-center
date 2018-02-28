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
      context 'when `request` event' do
        subject do
          build(:maintenance_window_state_transition, event: :request)
        end

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

      context 'when `cancel` event' do
        subject do
          build(:maintenance_window_state_transition, event: :cancel)
        end

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

      context 'when `reject` event' do
        subject do
          build(:maintenance_window_state_transition, event: :reject)
        end

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
    end
  end
end
