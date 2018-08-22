require 'rails_helper'

RSpec.describe 'Import cluster components', type: :feature do
  let(:cluster) { create(:cluster) }
  let(:admin) { create(:admin) }

  it 'imports from file successfully' do
    visit import_cluster_components_path(cluster, as: admin)

    attach_file 'Select Benchware export file:', Rails.root + 'spec/fixtures/benchware-ex.yml'
    click_button 'Import Benchware definitions'

    expect(find('.alert-success')).to have_text 'Imported 28 new components and updated 0 existing components'

    expect(cluster.components.count).to eq 28
    expect(cluster.component_groups.count).to eq 13

    master1 = cluster.components.find_by(name: 'master1')
    expect(master1).not_to be nil
    expect(master1.component_group.name).to eq 'Masters'

    node1 = cluster.components.find_by(name: 'node01')
    expect(node1).not_to be nil
    expect(node1.component_group.name).to eq 'Compute nodes'
    expect(node1.component_type).to eq 'NOT IMPLEMENTED'

  end
end
