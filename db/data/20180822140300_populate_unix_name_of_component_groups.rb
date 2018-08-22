class PopulateUnixNameOfComponentGroups < ActiveRecord::Migration[5.2]

  NAME_MAPPING = {
    'Compute nodes' => 'nodes',
    'Ethernet switches' => 'sw',
    'GPU nodes' => 'gpu',
    'Himem nodes' => 'himem',
    'Infiniband switches' => 'ibsw',
    'Infrastructure nodes' => 'infra',
    'Login nodes' => 'login',
    'Lustre MDS' => 'mds',
    'Lustre OSS' => 'oss',
    'Masters' => 'master',
    'NFS servers' => 'nfs',
    'Site nodes' => 'admin',
    'Viz nodes' => 'viz',
    'Xeon Phi nodes' => 'phi',
  }.freeze

  def up
    ComponentGroup.all.each do |group|
      if NAME_MAPPING.include? group.name
        group.unix_name = NAME_MAPPING[group.name]
        group.save!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
