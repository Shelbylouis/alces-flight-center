class AddCanonicalNameToClustersAndSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :canonical_name, :string
    add_column :clusters, :canonical_name, :string
  end
end
