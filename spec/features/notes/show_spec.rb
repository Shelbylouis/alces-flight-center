require 'rails_helper'

RSpec.describe 'Show notes page', type: :feature do
  let(:site) { create(:site) }
  let(:cluster) { create(:cluster, site: site) }

  let(:path) { cluster_notes_path(cluster, :customer, as: user) }

  # This context actually tests what is rendered by `new` view, which is
  # rendered by `show` action when there are no notes already.
  context 'when no notes already' do
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
