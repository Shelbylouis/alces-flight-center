require 'rails_helper'

RSpec.describe 'Cases table', type: :feature do
  let! :contact { create(:contact, site: site) }
  let! :admin { create(:admin) }
  let :site { create(:site) }
  let :cluster { create(:cluster, site: site) }

  let! :open_case do
    create(:open_case, cluster: cluster, details: 'Open case')
  end

  let! :archived_case do
    create(:archived_case, cluster: cluster, details: 'Archived case')
  end

  RSpec.shared_examples 'open cases table rendered' do
    it 'renders table of open Cases' do
      visit path

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

  context 'when user is contact' do
    let :user { contact }

    context 'when visit site dashboard' do
      let :path { root_path(as: user) }

      include_examples 'open cases table rendered'
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

  context 'when user is admin' do
    let :user { admin }

    context 'when visit site dashboard' do
      let :path { site_path(site, as: user) }

      # At least for now, want to render open Cases table on Site dashboard the
      # same for both admins as contacts.
      include_examples 'open cases table rendered'
    end

    context 'when visit cases page' do
      it 'renders table of all Cases, without Contact-specific buttons/info' do
        visit site_cases_path(site, as: user)

        # XXX Displaying details disabled at the moment due to space
        # constraints - either remove these or add back after reorganizing
        # table.
        # cases = all('tr').map(&:text)
        # expect(cases).to have_text('Open case')
        # expect(cases).to have_text('Archived case')

        headings = all('th').map(&:text)
        expect(headings).not_to include('Contact support')
        expect(headings).not_to include('Archive/Restore')

        links = all('a')

        mailto_links = links.select { |a| a[:href].match?('mailto') }
        expect(mailto_links).to eq []

        archive_links = links.select { |a| a[:href].match?('archive') }
        expect(archive_links).to eq []

        expect do
          find('.archived-case-row')
        end.to raise_error(Capybara::ElementNotFound)
      end

      ['resolved', 'rejected', 'deleted'].each do |completion_status|
        it "reloads Case ticket status on load until reaches #{completion_status}" do
          expect(Case.request_tracker).to receive(:show_ticket).thrice.and_return(
            OpenStruct.new(status: 'open'),
            OpenStruct.new(status: completion_status),
            OpenStruct.new(status: 'stalled'),
          )

          # Neither Case's ticket has reached completion status yet so both
          # should have reloaded RT ticket status.
          visit site_cases_path(site, as: user)
          expect(open_case.reload.last_known_ticket_status).to eq 'open'
          expect(archived_case.reload.last_known_ticket_status).to eq completion_status

          tds = all('td').map(&:text)
          expect(tds).to include('open')
          expect(tds).to include(completion_status)

          # Archived Case has reached completion status so ticket status is not
          # reloaded.
          visit site_cases_path(site, as: user)
          expect(open_case.reload.last_known_ticket_status).to eq 'stalled'
          expect(archived_case.reload.last_known_ticket_status).to eq completion_status

          tds = all('td').map(&:text)
          expect(tds).to include('stalled')
          expect(tds).to include(completion_status)

          headings = all('th').map(&:text)
          expect(headings).to include('Ticket status')
        end
      end
    end
  end
end