class AddPlaceholderMotds < ActiveRecord::DataMigration
  def up
    Cluster.update_all(
      motd: 'Placeholder MOTD - need to set real value before release'
    )
  end
end
