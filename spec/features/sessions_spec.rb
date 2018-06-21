require 'json_web_token'
require 'rails_helper'

RSpec.feature 'Sessions (home page)', type: :feature do

  let(:site) { create(:site, name: 'My Site') }

  context 'when logged in as contact' do
    let(:user) { create(:contact, site: site) }

    it 'shows contact\'s site dashboard' do
      visit root_path(as: user)

      expect(find('.title-card')).to have_text 'Site Dashboard: My Site'
    end
  end

  context 'when logged in as admin' do
    let(:user) { create(:admin) }

    it 'shows \'all sites\' dashboard' do
      visit root_path(as: user)

      expect(find('.title-card')).to have_text 'All Sites Dashboard'
    end
  end

  context 'when not logged in' do
    it 'politely suggests logging in' do
      visit root_path

      expect do
        find('.title-card')
      end.to raise_error(Capybara::ElementNotFound)

      expect(find('.sign-in')).to have_text 'Please sign in to Flight'
    end
  end

  context 'when logged in to SSO without a Center account' do
    let(:valid_token) {
      ::JsonWebToken.encode(email: 'otherwise_unused_email@example.com')
    }

    it 'shows the \'account not authorised\' message' do
      create_cookie('flight_sso', valid_token)
      visit root_path

      expect do
        find('.title-card')
      end.to raise_error(Capybara::ElementNotFound)

      expect(find('.sign-in')).to have_text 'Account not authorised'
    end
  end

end
