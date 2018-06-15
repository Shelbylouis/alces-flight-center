require 'rails_helper'

RSpec.describe 'Show notes page', type: :feature do
  it_behaves_like 'button is disabled for viewers' do
    let(:site) { create(:site) }
    let(:cluster) { create(:cluster, site: site) }

    let(:path) { cluster_notes_path(cluster, :customer, as: user) }
    let(:button_text) { 'Create notes' }
    let(:disabled_button_title) do
      'As a viewer you cannot create cluster notes'
    end
  end
end
