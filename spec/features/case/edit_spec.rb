require 'rails_helper'

RSpec.describe 'Case editing', type: :feature do

  let(:kase) { create(:open_case, subject: 'Original subject') }
  let!(:issue) {
    create(
      :issue,
      requires_component: false,
      requires_service: false,
      name: 'Some other issue'
    )
  }

  before(:each) do
    visit cluster_case_path(kase.cluster, kase, as: user)
  end

  context 'as a non-admin' do
    let(:user) { create(:contact, site: kase.site) }

    it 'does not show subject edit button' do
      expect do
        find('#case-subject-edit')
      end.to raise_error Capybara::ElementNotFound
    end

    it 'does not show issue edit selectbox' do
      expect do
        find('#case_issue_id')
      end.to raise_error Capybara::ElementNotFound
    end

  end

  context 'as an admin' do
    let(:user) { create(:admin) }

    let(:emails) { ActionMailer::Base.deliveries }

    before(:each) do
      emails.clear
    end

    context 'when editing case subject' do
      subject {
        find('#case-subject-edit').click
        fill_in 'case[subject]', with: 'New subject'
        click_button 'Change subject'
      }
      let(:notification_method) { :subject_notification }
      let(:slack_args) { [kase, 'Original subject', 'New subject'] }

      it 'can be edited successfully' do
        subject

        expect(find('.alert-success')).to have_text "Support case #{kase.display_id} updated."

        event_cards = all('.event-card')

        expect(event_cards[0].find('.card-body').text).to eq(
          'Changed the subject of this case from \'Original subject\' to \'New subject\'.'
        )

        kase.reload

        expect(kase.subject).to eq 'New subject'

        expect(emails.count).to eq 1
        expect(emails[0].subject).to have_text 'New subject'
      end

      include_examples 'Slack'
    end

    context 'when editing case issue' do
      subject {
        select 'Some other issue'
        click_button 'Change issue'
       }
      let(:notification_method) { :issue_notification }
      let(:slack_args) { [kase, 'New user/group', 'Some other issue'] }

      it 'allows editing case issue' do
        expect(kase.issue).not_to eq issue

        subject
        expect(find('.alert-success')).to have_text "Support case #{kase.display_id} updated."

        event_cards = all('.event-card')

        expect(event_cards[0].find('.card-body').text)
          .to eq(
        'Changed this case\'s associated issue from \'New user/group\' to \'Some other issue\'.'
        )

        kase.reload
        expect(kase.issue).to eq issue

        expect(emails.count).to eq 1
        expect(emails[0].parts.first.body.raw_source).to \
          have_text 'This case\'s associated issue has been changed from \'New user/group\' to \'Some other issue\''
      end

      include_examples 'Slack'
    end
  end
end
