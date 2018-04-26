require 'rails_helper'

RSpec.describe CaseStateTransition, type: :model do

  subject do
    build(:case_state_transition, event: event, user: user)
  end

  %w(resolve archive).each do |event|
    context "when `#{event}` event" do
      let(:event) { event }
      let(:user) { create(:admin) }

      it_behaves_like 'it must be initiated by an admin'
      it { is_expected.to validate_presence_of(:user) }
    end
  end
end
