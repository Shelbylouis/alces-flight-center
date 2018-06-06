require 'rails_helper'

RSpec.describe LogPolicy do
  include_context 'policy'

  let(:record) { nil }

  permissions :create?, :new? do
    it_behaves_like 'it is available only to admins'
  end
end
