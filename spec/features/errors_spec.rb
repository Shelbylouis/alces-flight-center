require 'rails_helper'

RSpec.describe 'Error handling', type: :feature do

  let(:cluster) { create(:cluster) }
  let(:user) { create(:contact) }

  describe '404 (#not_found)' do

    context 'when user not signed in' do

      it 'shows SSO login button' do
        visit cluster_path(cluster)

        expect(page).to have_http_status(404)

        card_body = find('.page-container .card-body')
        expect(card_body.find('.sign-in-button')).to have_text 'Sign in'
      end

    end

    context 'when contact signed in' do
      it 'does not show SSO login button' do
        visit cluster_path(cluster, as: user)

        expect(page).to have_http_status(404)

        card_body = find('.page-container .card-body')
        expect do
          card_body.find('.sign-in-button')
        end.to raise_error Capybara::ElementNotFound
      end
    end

  end

end
