class FixNamesOfComponentGroups < ActiveRecord::Migration[5.2]

  REQUESTED_FIXES = {
    'Compute Nodes' => 'Compute nodes',
    'Ethernet Switches' => 'Ethernet switches',
    'GPU Nodes' => 'GPU nodes',
    'Infiniband Switches' => 'Infiniband switches',
    'Login Nodes' => 'Login nodes',
    'Site Nodes' => 'Site nodes',
  }.freeze

  def up
    ComponentGroup.all.each do |group|
      if REQUESTED_FIXES.include?(group.name)
        group.name = REQUESTED_FIXES[group.name]
        group.save!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
