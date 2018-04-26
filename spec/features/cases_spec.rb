require 'rails_helper'

RSpec.describe 'Cases table', type: :feature do
  let! :contact { create(:contact, site: site) }
  let! :admin { create(:admin) }
  let :site { create(:site, name: 'My Site') }
  let :cluster { create(:cluster, site: site) }

  let! :open_case do
    create(:open_case, cluster: cluster, subject: 'Open case')
  end

  let! :resolved_case do
    create(:resolved_case, cluster: cluster, subject: 'Resolved case', completed_at: 1.days.ago, rt_ticket_id: nil)
  end

  let! :archived_case do
    create(:archived_case, cluster: cluster, subject: 'Archived case', completed_at: 2.days.ago)
  end

  RSpec.shared_examples 'open cases table rendered' do
    it 'renders table of open Cases' do
      visit path

      cases = all('tr').map(&:text)
      expect(cases).to have_text('Open case')
      expect(cases).not_to have_text('Resolved case')
      expect(cases).not_to have_text('Archived case')

      headings = all('th').map(&:text)
      expect(headings).to include('Contact support')

      links = all('a').map { |a| a[:href] }
      expect(links).to include(open_case.mailto_url)
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
        expect(cases).to have_text('Resolved case')
        expect(cases).to have_text('Archived case')

        headings = all('th').map(&:text)
        expect(headings).to include('Contact support')

        links = all('a').map { |a| a[:href] }
        expect(links).to include(open_case.mailto_url)

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
    end
  end
end

RSpec.describe 'Case page' do
  let (:contact) { create(:contact, site: site) }
  let (:admin) { create(:admin) }
  let (:site) { create(:site, name: 'My Site') }
  let (:cluster) { create(:cluster, site: site) }

  let! :open_case do
    create(:open_case, cluster: cluster, subject: 'Open case')
  end

  let! :resolved_case do
    create(:resolved_case, cluster: cluster, subject: 'Resolved case')
  end

  let! :archived_case do
    create(:archived_case, cluster: cluster, subject: 'Archived case', completed_at: 2.days.ago)
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

  it 'shows or hides add comment form for contacts' do
    visit case_path(open_case, as: contact)

    form = find('#new_case_comment')
    form.find('#case_comment_text')

    expect(form.find('input').value).to eq 'Add new comment'

    # No resolve/archive controls
    expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)

    visit case_path(resolved_case, as: contact)
    expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
    expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)

    visit case_path(archived_case, as: contact)
    expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
    expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)
  end

  it 'shows or hides add comment form and state controls for admins' do
    visit case_path(open_case, as: admin)

    form = find('#new_case_comment')
    form.find('#case_comment_text')

    expect(form.find('input').value).to eq 'Add new comment'

    expect(find('#case-state-controls').find('a').text).to eq 'Resolve this case'

    visit case_path(resolved_case, as: admin)
    expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
    expect(find('#case-state-controls').find('a').text).to eq 'Archive this case'

    visit case_path(archived_case, as: admin)
    expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
    expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)
  end

end
