require 'rails_helper'

RSpec.describe ChangeMotdRequest, type: :model do
  it { is_expected.to validate_presence_of(:motd) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to belong_to(:case) }
  it { is_expected.to have_many(:change_motd_request_state_transitions) }

  describe 'states' do
    RSpec.shared_examples 'it can be applied' do
      it 'can be applied' do
        admin = create(:admin)
        subject.apply!(admin)

        expect(subject).to be_applied
        expect(subject.transitions.last.user).to eq admin
      end
    end

    it 'is initially in unapplied state' do
      request = create(:change_motd_request)

      expect(request).to be_unapplied
    end

    context 'when unapplied' do
      subject { create(:change_motd_request, state: :unapplied) }

      it_behaves_like 'it can be applied'
    end

    context 'when applied' do
      subject { create(:change_motd_request, state: :applied) }

      it_behaves_like 'it can be applied'
    end
  end
end
