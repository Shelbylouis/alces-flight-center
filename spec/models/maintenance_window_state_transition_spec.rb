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
  end
end
