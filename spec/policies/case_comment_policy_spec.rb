require 'rails_helper'

RSpec.describe CaseCommentPolicy do
  include_context 'policy'

  permissions :create? do
    let(:user) { build_stubbed(:user) }
    let(:comment) { build_stubbed(:case_comment, case: kase) }
    let(:kase) { build_stubbed(:case) }

    it 'denies access when commenting is disabled on the Case' do
      allow(kase).to receive(:commenting_enabled_for?).with(user).and_return(false)

      expect(subject).not_to permit(user, comment)
    end

    it 'grants access when commenting is enabled on the Case' do
      allow(kase).to receive(:commenting_enabled_for?).with(user).and_return(true)

      expect(subject).to permit(user, comment)
    end
  end
end
