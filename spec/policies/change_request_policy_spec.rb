require 'rails_helper'

RSpec.describe ChangeRequestPolicy do
  include_context 'policy'

  let(:record) { nil }

  permissions :new?, :create?, :edit?, :update?, :propose?, :handover? do
    it_behaves_like 'it is available only to admins'
  end

  permissions :authorise?, :decline?, :complete? do
    it_behaves_like 'it is available only to contacts'
  end
end
