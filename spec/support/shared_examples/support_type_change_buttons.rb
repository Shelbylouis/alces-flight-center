require 'rails_helper'

RSpec.shared_examples 'can request support_type change via buttons' do |part_name|
  part_class_name = part_name.to_s.titlecase

  before :each do
    create(:"request_#{part_name}_becomes_managed_issue")
    create(:"request_#{part_name}_becomes_advice_issue")
  end

  let(:request_self_management_text) { 'Request self-management' }
  let(:request_alces_management_text) { 'Request Alces management' }

  let(:site) { create(:site) }
  let(:contact) { create(:contact, site: site) }
  let(:cluster) { create(:cluster, site: site) }

  let :cluster_parts_path do
    send("cluster_#{part_name.to_s.pluralize}_path", cluster, as: contact)
  end

  it "can request self-management of a managed #{part_class_name}" do
    part = create("managed_#{part_name}", cluster: cluster)

    visit cluster_parts_path
    click_button 'Request self-management'

    created_case = part.cases.first
    expect(created_case.send(part_name)).to eq(part)
    issue = Issue.send("request_#{part_name}_becomes_advice_issue")
    expect(created_case.issue).to eq(issue)
    tier = issue.tiers.first
    expect(created_case.fields).to eq(tier.fields)
    expect(created_case.tier_level).to eq(tier.level)
  end

  it "can request Alces management of an advice-only #{part_class_name}" do
    part = create("advice_#{part_name}", cluster: cluster)

    visit cluster_parts_path
    click_button request_alces_management_text

    created_case = part.cases.first
    expect(created_case.send(part_name)).to eq(part)
    issue = Issue.send("request_#{part_name}_becomes_managed_issue")
    expect(created_case.issue).to eq(issue)
    tier = issue.tiers.first
    expect(created_case.fields).to eq(tier.fields)
    expect(created_case.tier_level).to eq(tier.level)
  end

  it "displays no buttons for internal #{part_class_name}" do
    part = create(part_name, internal: true, cluster: cluster)

    visit cluster_parts_path
    # Sanity check that part itself is actually being displayed.
    expect(page).to have_text(part.name)

    expect(page).not_to have_button(request_self_management_text)
    expect(page).not_to have_button(request_alces_management_text)
  end
end
