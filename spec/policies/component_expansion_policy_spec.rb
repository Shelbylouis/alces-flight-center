require 'rails_helper'

RSpec.describe ComponentExpansionPolicy do
  include_context 'policy'

  let(:record) { nil }

  permissions :create?, :update?, :destroy? do
    it_behaves_like 'it is available only to admins'
  end
end
