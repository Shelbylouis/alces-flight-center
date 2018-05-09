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
    create(:resolved_case, cluster: cluster, subject: 'Resolved case', completed_at: 1.days.ago)
  end

  let! :closed_case do
    create(:closed_case, cluster: cluster, subject: 'Closed case', completed_at: 2.days.ago)
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
    let :user { contact }

    context 'when visit site cases dashboard' do
      let :path { cases_path(as: user) }

      include_examples 'open cases table rendered'
    end

    context 'when visit archive cases page' do
      it 'renders table of all resolved or closed Cases' do
        visit resolved_cases_path(as: user)

        cases = all('tr').map(&:text)
        expect(cases).not_to have_text('Open case')
        expect(cases).to have_text('Resolved case')
        expect(cases).to have_text('Closed case')
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
      it 'renders table of all resolved and closed Cases, without Contact-specific buttons/info' do
        visit resolved_site_cases_path(site, as: user)

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
  let! (:contact) { create(:contact, site: site) }
  let! (:admin) { create(:admin) }
  let (:site) { create(:site, name: 'My Site') }
  let (:cluster) { create(:cluster, site: site) }
  let (:assignee) { nil }

  let :open_case do
    create(:open_case, cluster: cluster, subject: 'Open case', assignee: assignee)
  end

  let :resolved_case do
    create(:resolved_case, cluster: cluster, subject: 'Resolved case')
  end

  let :closed_case do
    create(:closed_case, cluster: cluster, subject: 'Closed case', completed_at: 2.days.ago)
  end

  let (:mw) { create(:maintenance_window, case: open_case) }

  let :comment_form_class { '#new_case_comment' }
  let :comment_button_text { 'Add new comment' }

  describe 'events list' do
    it 'shows events in reverse chronological order' do
      create(:case_comment, case: open_case, user: admin, created_at: 2.hours.ago, text: 'Second')
      create(
        :maintenance_window_state_transition,
        maintenance_window: mw,
        user: admin,
        event: :request
      )
      create(:case_comment, case: open_case, user: admin, created_at: 4.hours.ago, text: 'First')

      # Generate an assignee-change audit entry
      open_case.assignee = admin
      # ...and a time-worked one
      open_case.time_worked = 123
      open_case.save


      visit case_path(open_case, as: admin)

      event_cards = all('.event-card')
      expect(event_cards.size).to eq(5)

      expect(event_cards[4].find('.card-body').text).to eq('First')
      expect(event_cards[3].find('.card-body').text).to eq('Second')
      expect(event_cards[2].find('.card-body').text).to match(
        /Maintenance requested for .* from .* until .* by A Scientist; to proceed this maintenance must be confirmed on the cluster dashboard/
      )

      expect(event_cards[1].find('.card-body').text).to eq 'Changed time worked from 0m to 2h 3m.'

      expect(event_cards[0].find('.card-body').text).to eq(
          'Assigned this case to A Scientist.'
      )
    end

    it 'does not show time-worked events to contacts' do
      open_case.time_worked = 1138
      open_case.save

      visit case_path(open_case, as: contact)

      open_case.reload

      expect(open_case.audits.count).to eq 1  # It's there...
      expect do
        find('.event-card')
      end.to raise_error(Capybara::ElementNotFound) # ...but we don't show it
    end
  end

  describe 'comments form' do
    it 'shows or hides add comment form for contacts' do
      visit case_path(open_case, as: contact)

      form = find('#new_case_comment')
      form.find('#case_comment_text')

      expect(form.find('input').value).to eq 'Add new comment'

      visit case_path(resolved_case, as: contact)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)

      visit case_path(closed_case, as: contact)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
    end

    it 'shows or hides add comment form for admins' do
      visit case_path(open_case, as: admin)

      form = find('#new_case_comment')
      form.find('#case_comment_text')

      expect(form.find('input').value).to eq 'Add new comment'

      visit case_path(resolved_case, as: admin)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)

      visit case_path(closed_case, as: admin)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
    end
  end

  describe 'state controls' do
    it 'hides state controls for contacts' do
      visit case_path(open_case, as: contact)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)

      visit case_path(resolved_case, as: contact)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)

      visit case_path(closed_case, as: contact)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)
    end

    it 'shows or hides state controls for admins' do
      visit case_path(open_case, as: admin)

      expect(find('#case-state-controls').find('a').text).to eq 'Resolve this case'

      visit case_path(resolved_case, as: admin)
      expect(find('#case-state-controls').find('input[type=submit]').value).to eq 'Set charge and close case'

      visit case_path(closed_case, as: admin)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)
    end
  end

  describe 'case assignment' do
    it 'hides assignment controls for contacts' do
      visit case_path(open_case, as: contact)
      assignment_td = find('#case-assignment')
      expect { assignment_td.find('input') }.to raise_error(Capybara::ElementNotFound)
      expect(assignment_td.text).to eq('Nobody')
    end

    it 'displays assignment controls for admins' do
      visit case_path(open_case, as: admin)
      assignment_select = find('#case-assignment').find('select')

      options = assignment_select.all('option').map(&:text)
      expect(options).to eq(['Nobody', 'A Scientist', '* A Scientist'])
    end

    context 'when a case has an assignee' do
      let(:assignee) { contact }
      it 'preselects the current assignee' do
        visit case_path(open_case, as: admin)
        assignment_select = find('#case-assignment').find('select')

        expect(assignment_select.value).to eq(contact.id.to_s)
      end
    end
  end
  
  describe 'Commenting' do

    context 'for open non-consultancy Case' do
      subject { create(:open_case, cluster: cluster, tier_level: 2) }

      it 'disables commenting for site contact' do
        visit case_path(subject, as: contact)

        form = find(comment_form_class)
        expect(form.find('textarea')).to be_disabled
        expect(form).to have_button(comment_button_text, disabled: true)
      end
    end

    it 'allows a comment to be added' do
      visit case_path(open_case, as: admin)

      fill_in 'case_comment_text', with: 'This is a test comment'
      click_button 'Add new comment'

      open_case.reload

      expect(open_case.case_comments.count).to be 1
      expect(find('.event-card').find('.card-body').text).to eq('This is a test comment')
      expect(find('.alert')).to have_text('New comment added')
    end

    it 'does not allow empty comments' do
      visit case_path(open_case, as: admin)

      fill_in 'case_comment_text', with: ''
      click_button 'Add new comment'

      open_case.reload

      expect(open_case.case_comments.count).to be 0
      expect(find('.alert')).to have_text('Empty comments are not permitted')
    end

  end

  describe 'time logging' do

    let (:time_form_id) { '#case-time-form' }
    let (:time_form_submit_button) { 'Change time worked' }

    RSpec.shared_examples 'time display' do
      it 'correctly displays existing time in hours and minutes' do
        visit case_path(subject, as: admin)

        form = find(time_form_id)
        expect(form.find_field('time[hours]', disabled: :all).value).to eq "2"
        expect(form.find_field('time[minutes]', disabled: :all).value).to eq "17"
      end

      it 'doesn\'t show time worked to contacts' do
        visit case_path(subject, as: contact)
        expect { find(time_form_id) }.to raise_error(Capybara::ElementNotFound)
      end
    end

    context 'for an open case' do
      subject do
        create(:open_case, cluster: cluster, time_worked: (2 * 60) + 17)
      end

      include_examples 'time display'

      it 'allows admins to set time worked' do
        visit case_path(subject, as: admin)

        fill_in 'time[hours]', with: '3'
        fill_in 'time[minutes]', with: '42'
        click_button time_form_submit_button

        subject.reload

        expect(subject.time_worked).to eq (3 * 60) + 42
      end


    end

    context 'for a resolved case' do
      subject do
        create(:resolved_case, cluster: cluster, time_worked: (2 * 60) + 17)
      end

      include_examples 'time display'

      it 'does not allow time worked to be changed' do
        visit case_path(subject, as: admin)

        expect(find_field('time[hours]', disabled: true)).to be_disabled
        expect(find_field('time[minutes]', disabled: true)).to be_disabled
        expect(find(time_form_id)).not_to \
          have_button(time_form_submit_button, disabled: :any)
      end
    end
  end
end
