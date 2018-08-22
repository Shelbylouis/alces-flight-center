require 'rails_helper'

RSpec.describe BenchwareImporter do

  let(:cluster) { create(:cluster) }

  let(:component_group) {
    create(:component_group, name: 'original group', cluster: cluster)
  }

  let(:importer) {
    BenchwareImporter.new(cluster)
  }

  let!(:component1) {
    create(
      :component,
      name: 'comp1',
      cluster: cluster,
      component_type: 'a type',
      component_group: component_group
    )
  }
  let!(:component2) {
    create(
      :component,
      name: 'comp2',
      cluster: cluster,
      component_type: 'a type',
      component_group: component_group
    )
  }

  it 'updates just the info field of existing components' do
    data = <<~DATA
      comp1:
        name: comp1
        type: another type
        primary_group: anothergroup
        secondary_groups: yetanothergroup,somedifferentgroup
        info: |
          This is some info
          It is informative
DATA

    new_comp, updated_comp = importer.from_text(data)

    component1.reload
    expect(component1.info).to include("This is some info\nIt is informative")
    expect(component1.component_group).to eq component_group

    expect(new_comp).to eq 0
    expect(updated_comp).to eq 1

  end

end
