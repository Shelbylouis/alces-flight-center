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
  let(:user) { create(:contact, site: site) }
  let(:cluster) { create(:cluster, site: site) }

  let :path do
    send("cluster_#{part_name.to_s.pluralize}_path", cluster, as: user)
  end

  context "when #{part_class_name} is managed" do
    let! :part do
      create("managed_#{part_name}", cluster: cluster)
    end

    let(:button_text) { request_self_management_text }

    it_behaves_like 'button is disabled for viewers' do
      let :disabled_button_title do
        "As a viewer you cannot request self-management of a #{part_name}"
      end
    end

    it 'can request self-management' do
      visit path
      click_button button_text

      created_case = part.cases.first
      expect(created_case.send(part_name.to_s.pluralize.to_sym).first).to eq(part)
      issue = Issue.send("request_#{part_name}_becomes_advice_issue")
      expect(created_case.issue).to eq(issue)
      tier = issue.tiers.first
      expect(created_case.fields).to eq(tier.fields)
      expect(created_case.tier_level).to eq(tier.level)
    end
  end

  context "when #{part_class_name} is advice-only" do
    let! :part do
      create("advice_#{part_name}", cluster: cluster)
    end

    let(:button_text) { request_alces_management_text }

    it_behaves_like 'button is disabled for viewers' do
      let :disabled_button_title do
        "As a viewer you cannot request Alces management of a #{part_name}"
      end
    end

    it "can request Alces management" do
      visit path
      click_button button_text

      created_case = part.cases.first
      expect(created_case.send(part_name.to_s.pluralize.to_sym).first).to eq(part)
      issue = Issue.send("request_#{part_name}_becomes_managed_issue")
      expect(created_case.issue).to eq(issue)
      tier = issue.tiers.first
      expect(created_case.fields).to eq(tier.fields)
      expect(created_case.tier_level).to eq(tier.level)
    end
  end

  context "when #{part_class_name} is internal" do
    let! :part do
      create(part_name, internal: true, cluster: cluster)
    end

    it 'displays no buttons' do
      visit path
      # Sanity check that part itself is actually being displayed.
      expect(page).to have_text(part.name)

      expect(page).not_to have_button(request_self_management_text)
      expect(page).not_to have_button(request_alces_management_text)
    end
  end
end
