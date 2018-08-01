require 'rails_helper'

RSpec.describe 'Case editing', type: :feature do

  let(:kase) { create(:open_case, subject: 'Original subject') }

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

  end

  context 'as an admin' do
    let(:user) { create(:admin) }

    let(:emails) { ActionMailer::Base.deliveries }

    before(:each) do
      emails.clear
    end

    it 'allows editing case subject' do
      find('#case-subject-edit').click
      fill_in 'case[subject]', with: 'New subject'
      click_button 'Change subject'

      expect(find('.alert-success')).to have_text "Support case #{kase.display_id} updated."

      expect(find('.event-card')).to \
        have_text 'Changed the subject of this case from \'Original subject\' to \'New subject\''

      kase.reload

      expect(kase.subject).to eq 'New subject'

      expect(emails.count).to eq 1
      expect(emails[0].subject).to have_text 'New subject'
    end
  end



end
