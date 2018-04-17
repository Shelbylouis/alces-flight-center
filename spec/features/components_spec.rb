require 'rails_helper'

RSpec.feature '/components/', type: :feature do
  before :each do
    # Prevent attempting to retrieve documents from S3 when Cluster page
    # visited.
    allow_any_instance_of(Cluster).to receive(:documents).and_return([])

    create(:request_component_becomes_managed_issue)
    create(:request_component_becomes_advice_issue)
  end

  let :site { create(:site) }
  let :contact { create(:contact, site: site) }
  let :cluster { create(:cluster, site: site) }

  it 'can request self-management of a managed Component' do
    component = create(:managed_component, cluster: cluster)

    visit cluster_components_path(cluster, as: contact)
    click_button 'Request self-management'

    created_case = component.cases.first
    expect(created_case.component).to eq(component)
    issue = Issue.request_component_becomes_advice_issue
    expect(created_case.issue).to eq(issue)
    tier = issue.tiers.first
    expect(created_case.fields).to eq(tier.fields)
    expect(created_case.tier_level).to eq(tier.level)
  end

  it 'can request Alces management of an advice-only Component' do
    component = create(:advice_component, cluster: cluster)

    visit cluster_components_path(cluster, as: contact)
    click_button 'Request Alces management'

    created_case = component.cases.first
    expect(created_case.component).to eq(component)
    issue = Issue.request_component_becomes_managed_issue
    expect(created_case.issue).to eq(issue)
    tier = issue.tiers.first
    expect(created_case.fields).to eq(tier.fields)
    expect(created_case.tier_level).to eq(tier.level)
  end
end
