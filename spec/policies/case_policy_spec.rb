require 'rails_helper'

RSpec.describe CasePolicy do
  include_context 'policy'

  let(:record) { create(:case, cluster: create(:cluster, site: site)) }

  permissions :create?, :new?, :escalate?, :assign_contact? do
    it_behaves_like 'it is available only to editors'
  end

  permissions :close?, :assign_engineer?, :resolve?, :set_time? do
    it_behaves_like 'it is available only to admins'
  end

  permissions :escalate? do
    it_behaves_like 'it is available only to editors'

    context 'for administrative case' do
      let(:issue) { create(:administrative_issue) }
      let(:record) {
        create(:case, cluster: create(:cluster, site: site), issue: issue)
      }

      it 'is not available' do
        expect(subject).not_to permit(admin, record)
        expect(subject).not_to permit(site_contact, record)
        expect(subject).not_to permit(site_viewer, record)
      end
    end
  end
end
