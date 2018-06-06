require 'rails_helper'

RSpec.describe MaintenanceWindowPolicy do
  include_context 'policy'

  let(:record) { nil }

  permissions :new?, :create?, :cancel?, :end?, :extend? do
    it_behaves_like 'it is available only to admins'
  end

  permissions :confirm?, :confirm_submit?, :reject? do
    it_behaves_like 'it is available only to contacts'
  end
end
