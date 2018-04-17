require 'rails_helper'

RSpec.feature '/services/', type: :feature do
  before :each do
    # Prevent attempting to retrieve documents from S3 when Cluster page
    # visited.
    allow_any_instance_of(Cluster).to receive(:documents).and_return([])

    create(:request_service_becomes_managed_issue)
    create(:request_service_becomes_advice_issue)
  end

  let :site { create(:site) }
  let :contact { create(:contact, site: site) }
  let :cluster { create(:cluster, site: site) }

  it 'can request self-management of a managed Service' do
    service = create(:managed_service, cluster: cluster)

    visit cluster_services_path(cluster, as: contact)
    click_button 'Request self-management'

    created_case = service.cases.first
    expect(created_case.service).to eq(service)
    issue = Issue.request_service_becomes_advice_issue
    expect(created_case.issue).to eq(issue)
    tier = issue.tiers.first
    expect(created_case.fields).to eq(tier.fields)
    expect(created_case.tier_level).to eq(tier.level)
  end

  it 'can request Alces management of an advice-only Service' do
    service = create(:advice_service, cluster: cluster)

    visit cluster_services_path(cluster, as: contact)
    click_button 'Request Alces management'

    created_case = service.cases.first
    expect(created_case.service).to eq(service)
    issue = Issue.request_service_becomes_managed_issue
    expect(created_case.issue).to eq(issue)
    tier = issue.tiers.first
    expect(created_case.fields).to eq(tier.fields)
    expect(created_case.tier_level).to eq(tier.level)
  end
end
