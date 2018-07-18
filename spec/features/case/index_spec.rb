require 'rails_helper'

RSpec.describe 'Cases table', type: :feature do
  let!(:contact) { create(:contact, site: site) }
  let!(:admin) { create(:admin) }
  let(:site) { create(:site, name: 'My Site') }
  let(:cluster) { create(:cluster, site: site) }

  let! :open_case do
    create(:open_case, cluster: cluster, subject: 'Open case')
  end

  let! :resolved_case do
    create(:resolved_case, cluster: cluster, subject: 'Resolved case', completed_at: 1.days.ago)
  end

  let! :closed_case do
    create(:closed_case,
           cluster: cluster,
           subject: 'Closed case',
           completed_at: 2.days.ago,
           credit_charge: build(:credit_charge, amount: 1138)
    )
  end

  RSpec.shared_examples 'open cases table rendered' do
    it 'renders table of open Cases' do
      visit path

      cases = all('tr').map(&:text)
      expect(cases).to have_text('Open case')
      expect(cases).not_to have_text('Resolved case')
      expect(cases).not_to have_text('Closed case')
    end
  end

  context 'when user is contact' do
    let(:user) { contact }

    context 'when visit site cases dashboard' do
      let(:path) { cases_path(state: 'open', as: user) }

      include_examples 'open cases table rendered'
    end

    context 'when applying state filter to cases page' do
      it 'renders table of all cases with given states' do
        visit cases_path(state: %w(resolved closed), as: user)

        cases = all('tr').map(&:text)
        expect(cases).not_to have_text('Open case')
        expect(cases).to have_text('Resolved case')
        expect(cases).to have_text('Closed case')
        expect(cases).to have_text('1138')
      end
    end

    it 'shows open cases assigned to current user in separate section' do
      create(
        :open_case,
        cluster: cluster,
        subject: 'Assigned case',
        assignee: user
      )
      create(
        :resolved_case,
        cluster: cluster,
        subject: 'Resolved assigned case',
        assignee: user
      )
      create(
        :closed_case,
        cluster: cluster,
        subject: 'Closed assigned case',
        assignee: user
      )

      visit cases_path(as: user)
      assigned_cases = find('.assigned-cases').all('tr').map(&:text)
      expect(assigned_cases).to have_text('Assigned case')
      expect(assigned_cases).not_to have_text('Open case')
      expect(assigned_cases).not_to have_text('Resolved assigned case')
      expect(assigned_cases).not_to have_text('Closed assigned case')
    end
  end

  context 'when user is admin' do
    let(:user) { admin }

    context 'when visit site cases dashboard' do
      let(:path) { site_cases_path(site, state: 'open', as: user) }

      # At least for now, want to render open Cases table on Site dashboard the
      # same for both admins as contacts.
      include_examples 'open cases table rendered'
    end
  end

  describe 'filtering' do
    let(:component1) { create(:component, cluster: cluster) }
    let(:component2) { create(:component, cluster: cluster) }

    let!(:component_case_1) {
      create(
        :open_case,
        cluster: cluster,
        components: [component1],
        subject: 'CC1',
        assignee: admin
      )
    }
    let!(:component_case_2) {
      create(
        :open_case,
        cluster: cluster,
        components: [component2],
        subject: 'CC2',
        assignee: admin
      )
    }
    let!(:component_case_3) {
      create(
        :open_case,
        cluster: cluster,
        components: [component1],
        subject: 'CC3'
      )
    }

    it 'filters by assignee' do
      visit cases_path(assigned_to: [admin], as: contact)
      cases = all('tr').map(&:text)
      expect(cases).to have_text('CC1')
      expect(cases).to have_text('CC2')
      expect(cases).not_to have_text('CC3')
    end

    it 'filters by association' do
      visit cases_path(associations: ["Component-#{component1.id}"], as: contact)
      cases = all('tr').map(&:text)
      expect(cases).to have_text('CC1')
      expect(cases).not_to have_text('CC2')
      expect(cases).to have_text('CC3')
    end

    it 'works with multiple active filters' do
      visit cases_path(
        assigned_to: [admin],
        associations: ["Component-#{component1.id}"],
        as: contact
      )
      cases = all('tr').map(&:text)
      expect(cases).to have_text('CC1')
      expect(cases).not_to have_text('CC2')
      expect(cases).not_to have_text('CC3')
    end
  end
end
