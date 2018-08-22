require 'rails_helper'

RSpec.describe BenchwareImporter do

  let(:cluster) { create(:cluster) }

  let(:component_group) {
    create(
      :component_group,
      name: 'original group',
      unix_name: 'original',
      cluster: cluster
    )
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
        secondary_group: yetanothergroup,somedifferentgroup
        info: |
          This is some info
          It is informative
DATA

    new_comp, updated_comp = importer.from_text(data)

    component1.reload
    expect(component1.info).to include("This is some info\nIt is informative")
    expect(component1.component_group).to eq component_group
    expect(component1.component_type).to eq 'a type'

    expect(new_comp).to eq 0
    expect(updated_comp).to eq 1

  end

  it 'creates a new component and group if neither already exist' do
    data = <<~DATA
      comp3:
        name: comp3
        type: another type
        primary_group: anothergroup
        secondary_group: yetanothergroup,somedifferentgroup
        info: |
          This is some info
          It is informative
    DATA

    new_comp, updated_comp = importer.from_text(data)

    component3 = cluster.components.find_by(name: 'comp3')
    expect(component3.component_group.name).to eq 'anothergroup'
    expect(component3.component_type).to eq 'another type'
    expect(component3.info).to include("This is some info\nIt is informative")

    expect(new_comp).to eq 1
    expect(updated_comp).to eq 0
  end

  it 'creates a new component in existing group if it exists' do
    data = <<~DATA
      comp3:
        name: comp3
        type: another type
        primary_group: original
        secondary_group: yetanothergroup,somedifferentgroup
        info: |
          This is some info
          It is informative
    DATA

    importer.from_text(data)

    component3 = cluster.components.find_by(name: 'comp3')
    expect(component3.component_group).to eq component_group
  end

  it 'creates a friendly name for a new group if known' do
    data = <<~DATA
      comp3:
        name: comp3
        type: another type
        primary_group: sw
        secondary_group: yetanothergroup,somedifferentgroup
        info: |
          This is some info
          It is informative
    DATA

    importer.from_text(data)

    component3 = cluster.components.find_by(name: 'comp3')
    expect(component3.component_group.name).to eq 'Ethernet switches'
  end

  it 'uses `nodes` secondary group if present' do
    data = <<~DATA
      comp3:
        name: comp3
        type: another type
        primary_group: sw
        secondary_group: yetanothergroup,nodes,somedifferentgroup
        info: |
          This is some info
          It is informative
    DATA

    importer.from_text(data)

    component3 = cluster.components.find_by(name: 'comp3')
    expect(component3.component_group.name).to eq 'Compute nodes'
  end

  it 'also works through #from_file' do
    data = <<~DATA
      comp3:
        name: comp3
        type: another type
        primary_group: anothergroup
        secondary_group: yetanothergroup,somedifferentgroup
        info: |
          This is some info
          It is informative
    DATA

    new_comp, updated_comp = importer.from_file(StringIO.new(data))

    component3 = cluster.components.find_by(name: 'comp3')
    expect(component3.component_group.name).to eq 'anothergroup'
    expect(component3.info).to include("This is some info\nIt is informative")

    expect(new_comp).to eq 1
    expect(updated_comp).to eq 0
  end

end
