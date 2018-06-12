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
      let(:path) { cases_path(as: user) }

      include_examples 'open cases table rendered'
    end

    context 'when visit archive cases page' do
      it 'renders table of all resolved or closed Cases' do
        visit resolved_cases_path(as: user)

        cases = all('tr').map(&:text)
        expect(cases).not_to have_text('Open case')
        expect(cases).to have_text('Resolved case')
        expect(cases).to have_text('Closed case')
        expect(cases).to have_text('1138')
      end
    end

    it 'shows cases assigned to current user in separate section' do
      create(
        :open_case,
        cluster: cluster,
        subject: 'Assigned case',
        assignee: user
      )

      visit cases_path(as: user)
      assigned_cases = find('.assigned-cases').all('tr').map(&:text)
      expect(assigned_cases).to have_text('Assigned case')
      expect(assigned_cases).not_to have_text('Open case')
    end
  end

  context 'when user is admin' do
    let(:user) { admin }

    context 'when visit site cases dashboard' do
      let(:path) { site_cases_path(site, as: user) }

      # At least for now, want to render open Cases table on Site dashboard the
      # same for both admins as contacts.
      include_examples 'open cases table rendered'
    end
  end
end
