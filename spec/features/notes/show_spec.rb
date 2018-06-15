require 'rails_helper'

RSpec.describe 'Show notes page', type: :feature do
  let(:site) { create(:site) }
  let(:cluster) { create(:cluster, site: site) }

  let(:path) { cluster_notes_path(cluster, :customer, as: user) }

  before :each do
    visit path
  end

  # This context actually tests what is rendered by `new` view, which is
  # rendered by `show` action when there are no notes already.
  context 'when no notes already' do
    let(:description) { :note_description }

    context 'for contact' do
      let(:user) { create(:contact, site: site) }

      it 'has textarea for note description' do
        expect do
          fill_in(description, with: 'words')
        end.not_to raise_error
      end
    end

    context 'for viewer' do
      let(:user) { create(:viewer, site: site) }

      it 'does not have textarea for note description' do
        expect do
          fill_in(description, with: 'words')
        end.to raise_error(Capybara::ElementNotFound)
      end
    end

    it_behaves_like 'button is disabled for viewers' do
      let(:button_text) { 'Create notes' }
      let(:disabled_button_title) do
        'As a viewer you cannot create cluster notes'
      end
    end
  end

  context 'when cluster already has notes' do
    before :each do
      create(:customer_note, cluster: cluster)
    end

    it_behaves_like 'button is disabled for viewers', button_link: true do
      let(:button_text) { 'Edit notes' }
      let(:disabled_button_title) do
        'As a viewer you cannot edit cluster notes'
      end
    end
  end
end
