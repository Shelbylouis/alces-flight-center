class DataModelChangesForTier1Tools < ActiveRecord::Migration[5.1]
  def change
    add_column :clusters, :motd, :text
    add_column :tiers, :tool, :text
  end
end
