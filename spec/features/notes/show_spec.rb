require 'rails_helper'

RSpec.describe 'Show notes page', type: :feature do
  let(:site) { create(:site) }
  let(:cluster) { create(:cluster, site: site) }

  let(:admin_note) { create(:engineering_note, cluster: cluster, description: 'I am admin note') }
  let(:user_note) { create(:customer_note, cluster: cluster, description: 'I am user note') }

  RSpec.shared_examples 'shows customer note' do
    it 'shows customer note' do
      visit cluster_note_path(cluster, user_note, as: user)
      expect(page.status_code).to eq 200
      expect(page.body).to have_text user_note.description
    end
  end

  RSpec.shared_examples 'does not show admin note' do
    it 'does not show admin note' do
      visit cluster_note_path(cluster, admin_note, as: user)
      expect(page.status_code).to eq 404
    end
  end

  context 'as an admin' do
    let(:user) { create(:admin) }

    include_examples 'shows customer note'

    it 'shows admin note' do
      visit cluster_note_path(cluster, admin_note, as: user)
      expect(page.status_code).to eq 200
    end
  end

  context 'as a contact' do
    let(:user) { create(:contact, site: site) }
    include_examples 'shows customer note'
    include_examples 'does not show admin note'
  end

  context 'as a viewer' do
    let(:user) { create(:viewer, site: site) }
    include_examples 'shows customer note'
    include_examples 'does not show admin note'

    it 'disables edit button' do
      visit cluster_note_path(cluster, user_note, as: user)
      expect do
        click_button 'Edit document'
      end.to raise_error Capybara::ElementNotFound
    end
  end
end
