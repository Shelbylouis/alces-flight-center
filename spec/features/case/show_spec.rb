require 'rails_helper'

RSpec.describe 'Case page' do
  let! (:contact) { create(:contact, site: site) }
  let! (:admin) { create(:admin) }
  let (:site) { create(:site, name: 'My Site') }
  let (:cluster) { create(:cluster, site: site) }
  let (:assignee) { nil }

  let :open_case do
    create(:open_case, cluster: cluster, subject: 'Open case', assignee: assignee, tier_level: 2)
  end

  let :resolved_case do
    create(:resolved_case, cluster: cluster, subject: 'Resolved case', tier_level: 2)
  end

  let :closed_case do
    create(:closed_case, cluster: cluster, subject: 'Closed case', completed_at: 2.days.ago, tier_level: 2)
  end

  let :consultancy_case do
    create(:open_case, cluster: cluster, subject: 'Open case', assignee: assignee, tier_level: 3)
  end

  let (:mw) { create(:maintenance_window, case: open_case) }

  let(:comment_form_class) { '#new_case_comment' }
  let(:comment_button_text) { 'Add new comment' }

  describe 'data display' do
    it 'shows table of fields for Case with fields' do
      field_name = 'Some field'
      field_value = 'Some value'
      kase = create(
        :case,
        fields: [{name: field_name, value: field_value}],
        cluster: cluster
      )

      visit case_path(kase, as: contact)

      header_text = all('th').map(&:text)
      expect(header_text).to include(field_name)
      data_text = all('td').map(&:text)
      expect(data_text).to include(field_value)
    end

    it 'shows requested MOTD for Case with associated ChangeMotdRequest' do
      motd = 'Some new MOTD'
      kase = create(
        :case,
        fields: nil,
        cluster: cluster,
        change_motd_request: build(:change_motd_request, motd: motd),
      )

      visit case_path(kase, as: contact)

      data_text = all('td').map(&:text)
      expect(data_text).to include(motd)
    end
  end

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
      # And an escalation entry
      open_case.tier_level = 3
      open_case.save

      # And a log entry
      create(:log, cases: [open_case], cluster: cluster, details: 'Loggy McLogface')

      visit case_path(open_case, as: admin)

      event_cards = all('.event-card')
      expect(event_cards.size).to eq(7)

      expect(event_cards[6].find('.card-body').text).to eq('First')
      expect(event_cards[5].find('.card-body').text).to eq('Second')
      expect(event_cards[4].find('.card-body').text).to match(
        /Maintenance requested for .* from .* until .* by A Scientist; to proceed this maintenance must be confirmed on the cluster dashboard/
      )
      expect(event_cards[3].find('.card-body').text).to eq 'Changed time worked from 0m to 2h 3m.'

      expect(event_cards[2].find('.card-body').text).to eq(
          'Assigned this case to A Scientist.'
      )
      expect(event_cards[1].find('.card-body').text).to eq(
          'Escalated this case to tier 3 (General Support).'
      )
      expect(event_cards[0].find('.card-body').text).to eq(
          'Loggy McLogface'
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
      visit case_path(consultancy_case, as: contact)

      form = find('#new_case_comment')
      form.find('#case_comment_text')

      expect(form.find('input').value).to eq 'Add new comment'

      visit case_path(open_case, as: contact)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)

      # Observe that case state overrides case tier in terms of why we report commenting
      # being disabled.
      visit case_path(resolved_case, as: contact)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
      expect(find('.card.bg-light').text).to match 'Commenting is disabled as this case is resolved.'

      visit case_path(closed_case, as: contact)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
      expect(find('.card.bg-light').text).to match 'Commenting is disabled as this case is closed.'
    end

    it 'shows or hides add comment form for admins' do
      visit case_path(consultancy_case, as: admin)

      form = find('#new_case_comment')
      form.find('#case_comment_text')

      expect(form.find('input').value).to eq 'Add new comment'

      visit case_path(open_case, as: admin)

      form = find('#new_case_comment')
      form.find('#case_comment_text')

      expect(form.find('input').value).to eq 'Add new comment'

      visit case_path(resolved_case, as: admin)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
      expect(find('.card.bg-light').text).to match 'Commenting is disabled as this case is resolved.'

      visit case_path(closed_case, as: admin)
      expect { find('#new_case_comment') }.to raise_error(Capybara::ElementNotFound)
      expect(find('.card.bg-light').text).to match 'Commenting is disabled as this case is closed.'
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

        expect do
          find(comment_form_class)
        end.to raise_error(Capybara::ElementNotFound)

        expect(find('.card.bg-light').text).to match 'This is a non-consultancy support case and so additional discussion is not available.'
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

    %w(resolved closed).each do |state|
      context "for a #{state} case" do
        subject { create("#{state}_case".to_sym, cluster: cluster, tier_level: 3) }

        it 'does not allow commenting by site contact' do
          visit case_path(subject, as: contact)
          expect do
            find('textarea')
          end.to raise_error(Capybara::ElementNotFound)
        end

        it 'does not allow commenting by admin' do
          visit case_path(subject, as: admin)
          expect do
            find('textarea')
          end.to raise_error(Capybara::ElementNotFound)
        end

      end
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

  describe 'escalation' do
    context 'for open tier 2 case' do
      subject do
        create(:open_case, tier_level:2)
      end
      it 'shows escalate button' do
        visit case_path(subject, as: admin)

        expect do
          find_button 'Escalate'
        end.not_to raise_error

        click_button 'Escalate'

        # Using find(...).click instead of click_button waits for modal to appear
        find('#confirm-escalate-button').click

        subject.reload
        expect(subject.tier_level).to eq 3
      end
    end

    RSpec.shared_examples 'for inapplicable cases' do
      it 'does not show escalate button' do
        visit case_path(subject, as: admin)

        expect do
          find_button 'Escalate'
        end.to raise_error(Capybara::ElementNotFound)
      end
    end

    context 'for open tier 3 case' do
      subject do
        create(:open_case, tier_level: 3)
      end
      it_behaves_like 'for inapplicable cases'
    end

    context 'for resolved tier 2 case' do
      subject do
        create(:resolved_case, tier_level: 2)
      end
      it_behaves_like 'for inapplicable cases'
    end

    context 'for closed tier 2 case' do
      subject do
        create(:closed_case, tier_level: 2)
      end
      it_behaves_like 'for inapplicable cases'
    end
  end

  describe 'maintenance window request' do

    RSpec.shared_examples 'does not show maintenance button' do
      it 'doesn\'t show maintenance button' do
        visit case_path(subject, as: user)
        expect do
          find('a', text: 'Request maintenance')
        end.to raise_error(Capybara::ElementNotFound)
      end
    end

    context 'for an open case' do
      subject { open_case }

      context 'as an admin' do
        let(:user) { admin }

        it 'shows button' do
          visit case_path(subject, as: user)

          request_link = find('a', text: 'Request maintenance')
          expect(request_link[:href]).to eq new_cluster_maintenance_window_path(cluster, case_id: open_case.id)
        end

        context 'as a contact' do
          let(:user) { contact }
          include_examples 'does not show maintenance button'
        end
      end
    end

    %w(resolved closed).each do |state|
      context "for a #{state} case" do
        subject do
          send("#{state}_case")
        end

        let(:user) { admin }

        include_examples 'does not show maintenance button'
      end
    end
  end

  describe 'applying requests' do
    subject do
      create(
        :case_with_change_motd_request,
        change_motd_request: request
      )
    end

    let(:request) { create(:change_motd_request, state: :unapplied) }

    let(:path) { case_path(subject, as: user) }
    let(:apply_button_text) { 'Done' }
    let(:reapply_button_text) { 'Already applied' }

    def assert_button_successfully_applies(button_text)
      expect do
        click_button button_text
      end.to change { request.reload.transitions.length }.by(1)

      expect(request).to be_applied
      expect(current_path).to eq(case_path(subject))
      expect(
        find('.alert')
      ).to have_text('The cluster has been updated to reflect this change.')
    end

    before :each do
      visit path
    end

    context 'when user is admin' do
      let(:user) { create(:admin) }

      it 'has warning-styled button' do
        button = find_button(apply_button_text)
        expect(button['class']).to include('btn-warning')
      end

      it 'can use button to apply request' do
        assert_button_successfully_applies(apply_button_text)
      end

      context 'when request has already been applied' do
        let(:request) { create(:change_motd_request, state: :applied) }

        it 'has danger-styled button' do
          button = find_button(reapply_button_text)
          expect(button['class']).to include('btn-danger')
        end

        it 'can use button to re-apply request' do
          assert_button_successfully_applies(reapply_button_text)
        end
      end
    end

    context 'when user is contact' do
      let(:user) { create(:contact, site: subject.site) }

      it 'is not shown either button' do
        [apply_button_text, reapply_button_text].each do |button_text|
          expect(page).not_to have_button(button_text)
        end
      end
    end
  end
end
