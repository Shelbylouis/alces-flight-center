class AddPlaceholderMotds < ActiveRecord::DataMigration
  def up
    Cluster.update_all(
      motd: <<~MOTD.strip_heredoc
        Placeholder MOTD - need to set real value before release.

        It can show across multiple lines too.
      MOTD
    )
  end
end
