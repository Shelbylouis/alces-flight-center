class CreateJoinTableClustersChecks < ActiveRecord::Migration[5.2]
  def change
    create_join_table :clusters, :checks, table_name: :cluster_checks do |t|
      t.index :cluster_id
      t.index :check_id
    end
  end
end
