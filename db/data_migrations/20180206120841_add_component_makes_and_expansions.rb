class AddComponentMakesAndExpansions < ActiveRecord::DataMigration
  def up
    add_expansion_types
    add_component_makes
    raise 'Exited correctly'
  end

  private

  NETWORK_EXP = 'Network expansion'

  def add_expansion_types
    [NETWORK_EXP, 'PSU', 'SAS'].each do |expansion|
      ExpansionType.create!(name: expansion)
    end
  end

  def add_component_makes
    add_server_make('1U Server')
    add_server_make('2U Server')
    add_network_switch_make
    add_disk_array_make
    add_virtual_server_make
  end

  def add_server_make(model)
    ComponentMake.create!(
      model: model, **generic, **component_type('Server')
    ).tap do |make|
      [
        { slot: 1, ports: 4, **expansion_type(NETWORK_EXP) },
        { slot: 2, ports: 1, **expansion_type('PSU') },
        { slot: 3, ports: 1, **expansion_type('PSU') }
      ].each { |opt| make.default_expansions.create!(**opt) }
    end
  end

  def add_network_switch_make
    ComponentMake.create!(
      model: 'Network switch', **generic, **component_type('Network switch')
    ).tap do |make|
      [
        { slot: 1, ports: 48, **expansion_type(NETWORK_EXP) },
        { slot: 2, ports: 1, **expansion_type('PSU') }
      ].each { |opt| make.default_expansions.create!(**opt) }
    end
  end

  def add_disk_array_make
    ComponentMake.create!(
      model: 'Disk array', **generic, **component_type('Disk array')
    ).tap do |make|
      [
        { slot: 1, ports: 1, **expansion_type('PSU') },
        { slot: 2, ports: 1, **expansion_type('PSU') },
        { slot: 3, ports: 4, **expansion_type('SAS') },
        { slot: 4, ports: 4, **expansion_type('SAS') }
      ].each { |opt| make.default_expansions.create!(**opt) }
    end
  end

  def add_virtual_server_make
    ComponentMake.create! model: 'libvert',
                          manufacturer: 'n/a',
                          knowledgebase_url: 'n/a',
                          **component_type('Virtual server')
  end

  def expansion_type(name)
    { expansion_type: ExpansionType.find_by_name!(name) }
  end

  def component_type(name)
    { component_type: ComponentType.find_by_name!(name) }
  end

  def generic
    { manufacturer: 'generic', knowledgebase_url: 'n/a' }
  end
end
