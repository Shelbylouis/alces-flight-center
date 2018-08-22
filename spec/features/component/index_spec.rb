require 'rails_helper'

RSpec.feature '/components/', type: :feature do
  it_behaves_like 'can request support_type change via buttons', :component

  describe 'filtering with ?type' do
    let(:admin) { create(:admin) }
    let(:cluster) { create(:cluster) }
    let!(:component_1) {
      create(
        :component,
        name: 'Component 1',
        component_type: 'Hyperdrive motivator',
        cluster: cluster
      )
    }
    let!(:component_2) {
      create(
        :component,
        name: 'Component 2',
        component_type: 'Heisenberg compensator',
        cluster: cluster
      )
    }

    it 'only lists matching components' do
      visit cluster_components_path(cluster, type: 'Heisenberg compensator', as: admin)

      expect(page.body).to have_text 'Component 2'
      expect(page.body).not_to have_text 'Component 1'
    end
  end
end
