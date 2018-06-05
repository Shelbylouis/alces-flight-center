require 'rails_helper'

RSpec.describe ChangeMotdRequestPolicy do
  include_context 'policy'

  let(:record) { nil }

  permissions :apply? do
    it_behaves_like 'it is available only to admins'
  end
end
