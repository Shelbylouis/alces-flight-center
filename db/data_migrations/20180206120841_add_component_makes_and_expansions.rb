class AddComponentMakesAndExpansions < ActiveRecord::DataMigration
  def up
    add_expansion_types
    add_component_makes
    raise 'Exited correctly'
  end

  private

  NETWORK_EXP = 'Network Expansion'

  def add_expansion_types
    [NETWORK_EXP, 'PSU', 'SAS'].each do |expansion|
      ExpansionType.create!(name: expansion)
    end
  end

  def add_component_makes
    make_1u_server
  end

  def make_1u_server
    ComponentMake.create!(
      model: '1U Server', **generic, **component_type('Server')
    ).tap do |make|
      [
        { slot: 1, ports: 4, **expansion_type(NETWORK_EXP) },
        { slot: 2, ports: 1, **expansion_type('PSU') },
        { slot: 3, ports: 1, **expansion_type('PSU') }
      ].each { |opt| make.default_expansions.create!(**opt) }
    end
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
