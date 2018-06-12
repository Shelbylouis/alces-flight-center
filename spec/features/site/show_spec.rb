require 'rails_helper'

RSpec.describe 'Site page', type: :feature do
  it_behaves_like 'button is disabled for viewers', button_tag: 'a' do
    let(:site) { create(:site) }
    let!(:cluster) { create(:cluster, site: site) }

    let(:path) { root_path(cluster, as: user) }
    let(:button_text) { 'Create case' }
    let(:disabled_button_title) do
      'As a viewer you cannot create a case'
    end
  end
end
