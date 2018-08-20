require 'rails_helper'

RSpec.describe 'Edit notes page', type: :feature do

  let(:site) { create(:site) }
  let(:cluster) { create(:cluster, site: site) }

  let(:admin_note) { create(:engineering_note, cluster: cluster, description: 'I am admin note') }
  let(:customer_note) { create(:customer_note, cluster: cluster, description: 'I am customer note') }

  RSpec.shared_examples 'edits customer note' do
    it 'allows editing customer note' do
      visit edit_cluster_note_path(cluster, customer_note, as: user)

      fill_in 'note_description', with: 'I am edited user note'
      click_button 'Save document'

      customer_note.reload

      expect(customer_note.description).to eq 'I am edited user note'
    end

    it 'allows deleting note by editing to empty' do
      visit edit_cluster_note_path(cluster, customer_note, as: user)

      fill_in 'note_description', with: ''
      click_button 'Save document'

      expect(find('.alert-success')).to have_text 'Document deleted.'
      expect do
        customer_note.reload
      end.to raise_error ActiveRecord::RecordNotFound
    end
  end

  RSpec.shared_examples 'disallows admin note' do
    it 'prohibits access to admin note editing' do
      visit edit_cluster_note_path(cluster, admin_note, as: user)
      expect(page.status_code).to eq 404
    end
  end

  context 'as an admin' do
    let(:user) { create(:admin) }

    include_examples 'edits customer note'

    it 'allows editing admin note' do
      visit edit_cluster_note_path(cluster, admin_note, as: user)

      fill_in 'note_description', with: 'I am edited admin note'
      click_button 'Save document'

      admin_note.reload

      expect(admin_note.description).to eq 'I am edited admin note'
    end

    it 'allows changing visibility' do
      visit edit_cluster_note_path(cluster, admin_note, as: user)

      select 'Customer and engineer', from: 'note_visibility'
      click_button 'Save document'

      admin_note.reload

      expect(admin_note.visibility).to eq 'customer'
    end
  end

  context 'as a contact' do
    let(:user) { create(:contact, site: site) }

    include_examples 'edits customer note'
    include_examples 'disallows admin note'

    it 'prevents changing visibility' do
      visit edit_cluster_note_path(cluster, customer_note, as: user)
      expect do
        select 'Engineers only', from: 'note_visibility'
      end.to raise_error Capybara::ElementNotFound
    end
  end

  context 'as a viewer' do
    let(:user) { create(:viewer, site: site) }

    it 'disallows editing of customer note' do
      visit edit_cluster_note_path(cluster, customer_note, as: user)
      expect(page.status_code).to eq 403
    end

    include_examples 'disallows admin note'
  end

end
