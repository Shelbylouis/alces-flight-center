require 'rails_helper'

RSpec.describe 'Cases table', type: :feature do
  let! :contact { create(:contact, site: site) }
  let :site { create(:site) }
  let :cluster { create(:cluster, site: site) }

  let! :open_case do
    create(:open_case, cluster: cluster, details: 'Open case')
  end

  let! :archived_case do
    create(:archived_case, cluster: cluster, details: 'Archived case')
  end

  context 'when user is contact' do
    let :user { contact }

    context 'when visit site dashboard' do
      it 'renders table of open Cases' do
        visit root_path(as: user)

        expect(page).to have_text('Open support cases')

        cases = all('tr').map(&:text)
        expect(cases).to have_text('Open case')
        expect(cases).not_to have_text('Archived case')

        headings = all('th').map(&:text)
        expect(headings).to include('Contact support')
        expect(headings).to include('Archive')

        links = all('a').map { |a| a[:href] }
        expect(links).to include(open_case.mailto_url)
        expect(links).to include(archive_case_path(open_case))
      end
    end

    context 'when visit cases page' do
      it 'renders table of all Cases' do
        visit cases_path(as: user)

        cases = all('tr').map(&:text)
        expect(cases).to have_text('Open case')

        headings = all('th').map(&:text)
        expect(headings).to include('Contact support')
        expect(headings).to include('Archive/Restore')

        links = all('a').map { |a| a[:href] }
        expect(links).to include(open_case.mailto_url)
        expect(links).to include(archive_case_path(open_case))

        archived_case_row = find('.archived-case-row')
        expect(archived_case_row).to have_text('Archived case')

        archived_case_links = archived_case_row.all('a').map { |a| a[:href] }
        expect(archived_case_links).not_to include(archived_case.mailto_url)
        expect(archived_case_links).to include(restore_case_path(archived_case))
      end
    end
  end

end
