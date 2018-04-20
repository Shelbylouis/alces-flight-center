require 'rails_helper'

RSpec.describe 'Cases table', type: :feature do
  let! :contact { create(:contact, site: site) }
  let! :admin { create(:admin) }
  let :site { create(:site, name: 'My Site') }
  let :cluster { create(:cluster, site: site) }

  let! :open_case do
    create(:open_case, cluster: cluster, subject: 'Open case')
  end

  let! :archived_case do
    create(:archived_case, cluster: cluster, subject: 'Archived case', completed_at: 2.days.ago)
  end

  RSpec.shared_examples 'open cases table rendered' do
    it 'renders table of open Cases' do
      visit path

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

    context 'when visit site cases dashboard' do
      let :path { cases_path(as: user) }

      include_examples 'open cases table rendered'
    end

    context 'when visit archive cases page' do
      it 'renders table of all Cases' do
        visit archives_cases_path(as: user)

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

    context 'when visit site cases dashboard' do
      let :path { site_cases_path(site, as: user) }

      # At least for now, want to render open Cases table on Site dashboard the
      # same for both admins as contacts.
      include_examples 'open cases table rendered'
    end

    context 'when visit archive cases page' do
      it 'renders table of all Cases, without Contact-specific buttons/info' do
        visit archives_site_cases_path(site, as: user)

        headings = all('th').map(&:text)
        expect(headings).not_to include('Contact support')
        expect(headings).not_to include('Archive/Restore')

        # Only include links in the table NOT the tab bar
        links = first('table').all('a')

        mailto_links = links.select { |a| a[:href]&.match?('mailto') }
        expect(mailto_links).to eq []

        archive_links = links.select { |a| a[:href]&.match?('archive') }
        expect(archive_links).to eq []

        expect do
          find('.archived-case-row')
        end.to raise_error(Capybara::ElementNotFound)
      end

      ['resolved', 'rejected', 'deleted'].each do |completion_status|
        it "reloads Case ticket status on load until reaches #{completion_status}" do
          expect(
            Case.request_tracker
          ).to receive(
            :show_ticket
          ).thrice do |ticket_id|
            # Return object with status specific to particular ticket given; do
            # this explicitly rather than using `and_return` with multiple
            # values as that was failing intermittently, likely due to it not
            # being entirely deterministic the order we request ticket info in.
            case ticket_id
            when open_case.rt_ticket_id
              OpenStruct.new(status: 'open')
            when archived_case.rt_ticket_id
              OpenStruct.new(status: completion_status)
            end
          end

          # Neither Case's ticket has reached completion status yet so both
          # should have reloaded RT ticket status.
          visit archives_site_cases_path(site, as: user)
          expect(open_case.reload.last_known_ticket_status).to eq 'open'
          expect(archived_case.reload.last_known_ticket_status).to eq completion_status

          tds = all('td').map(&:text)
          expect(tds).to include('open')
          expect(tds).to include(completion_status)

          # Archived Case has reached completion status so ticket status is not
          # reloaded.
          visit archives_site_cases_path(site, as: user)
          expect(open_case.reload.last_known_ticket_status).to eq 'open'
          expect(archived_case.reload.last_known_ticket_status).to eq completion_status

          tds = all('td').map(&:text)
          expect(tds).to include('open')
          expect(tds).to include(completion_status)

          headings = all('th').map(&:text)
          expect(headings).to include('Ticket status')
        end
      end
    end
  end
end

RSpec.describe 'Case page' do
  let! (:admin) { create(:admin) }
  let (:site) { create(:site, name: 'My Site') }
  let (:cluster) { create(:cluster, site: site) }

  let! :open_case do
    create(:open_case, cluster: cluster, subject: 'Open case')
  end

  let (:mw) { create(:maintenance_window, case: open_case) }

  it 'shows events in chronological order' do
    create(:case_comment, case: open_case, user: admin, created_at: 2.hours.ago, text: 'Second')
    create(
      :maintenance_window_state_transition,
      maintenance_window: mw,
      user: admin,
      event: :request
    )
    create(:case_comment, case: open_case, user: admin, created_at: 4.hours.ago, text: 'First')

    visit case_path(open_case, as: admin)

    event_cards = all('.event-card')
    expect(event_cards.size).to eq(3)

    expect(event_cards[0].find('.card-body').text).to eq('First')
    expect(event_cards[1].find('.card-body').text).to eq('Second')
    expect(event_cards[2].find('.card-body').text).to match(
      /Maintenance requested for .* from .* until .* by A Scientist; to proceed this maintenance must be confirmed on the cluster dashboard/
    )

  end

end
