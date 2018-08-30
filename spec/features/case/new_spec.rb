require 'rails_helper'

RSpec.describe 'Case form', type: :feature, js: true do
  let!(:cluster) { create(:cluster) }
  let!(:user) { create(:contact, site: cluster.site) }
  let!(:component) { create(:component, cluster: cluster) }
  let!(:service) { create(:service, cluster: cluster) }
  let! (:issue) do
    create(
      :issue,
      requires_service: true,
      service_type: service.service_type,
      requires_component: true
    )
  end
  let! :tier do
    create(
      :tier,
      level: 2,
      issue: issue,
      fields: [{
        name: 'Some field',
        type: 'input',
        optional: false,
        help: 'Some help',
      }]
    )
  end

  RSpec.shared_examples 'it allows Case creation' do
    it 'allows Case creation' do
      subject_value = 'my subject'
      field_value = 'my value'

      visit path
      select service.name, from: 'service'
      select issue.name, from: 'Issue'
      select component.name, from: 'component'
      fill_in 'subject', with: subject_value
      fill_in 'Some field', with: field_value
      expect do
        click_button 'Create Case'
      end.to change { cluster.reload.cases.length }.by(1)

      # Test all encoded fields in `app/javascript/packs/State.elm` are used in
      # the new Case.
      new_case = cluster.cases.first
      expect(new_case.cluster).to eq(cluster)
      expect(new_case.issue).to eq(issue)
      expect(new_case.components.first).to eq(component)
      expect(new_case.services.first).to eq(service)
      expect(new_case.subject).to eq(subject_value)
      expect(new_case.tier_level).to eq(tier.level)
      expect(new_case.fields).to eq([
        tier.fields[0].merge('value' => field_value)
      ])
      expect(new_case.contact).to eq(user)
    end
  end

  context 'when accessed at `/cases/new`' do
    let(:path) { new_case_path(as: user) }

    it_behaves_like 'it allows Case creation'
  end

  context 'when accessed at `/cluster/*/cases/new`' do
    let(:path) { new_cluster_case_path(cluster, as: user) }

    it_behaves_like 'it allows Case creation'
  end

  describe 'motd tool' do
    let!(:tier) do
      create(:tier_with_tool, issue: issue, tool: :motd)
    end

    it 'allows creation of Case with associated ChangeMotdRequest' do
      motd = 'My new MOTD'

      visit new_case_path(as: user)
      select service.name, from: 'service'
      select issue.name, from: 'Issue'
      select component.name, from: 'component'
      fill_in 'New MOTD', with: motd
      expect do
        click_button 'Create Case'
      end.to change { cluster.reload.cases.length }.by(1)

      new_case = cluster.cases.first
      expect(new_case.fields).to be_nil
      expect(new_case.change_motd_request.motd).to eq(motd)
    end
  end

  describe 'default case assignment as an admin' do
    let(:admin) { create(:admin) }
    let!(:contact) { create(:primary_contact, site: site, name: 'Mary Pri') }
    let(:site) { create(:site, default_assignee: admin) }
    let(:cluster) { create(:cluster, site: site) }
    let(:assigned_case) { create(:open_case, cluster: cluster) }

    it 'has an assigned engineer' do
      expect(assigned_case.assignee).to eq(admin)
    end

    it 'has an assigned contact' do
      expect(assigned_case.contact.name).to eq('Mary Pri')
    end
  end
end
