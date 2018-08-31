require 'rails_helper'

RSpec.describe CasePolicy do
  include_context 'policy'

  let(:record) { create(:case, cluster: create(:cluster, site: site)) }

  permissions :create?, :new?, :escalate? do
    it_behaves_like 'it is available only to editors'
  end

  permissions :close?, :assign_engineer?, :resolve?, :set_time? do
    it_behaves_like 'it is available only to admins'
  end
end
