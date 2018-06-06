require 'rails_helper'

RSpec.describe AssetRecordPolicy do
  include_context 'policy'

  let(:record) { nil }

  permissions :edit?, :update? do
    it_behaves_like 'it is available only to admins'
  end
end
