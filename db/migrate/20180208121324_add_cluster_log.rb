class AddClusterLog < ActiveRecord::Migration[5.1]
  def change
    create_table :cluster_logs do |t|
      t.text :details, null: false
      t.references :cluster, null: false
      t.references :user, null: false
      t.timestamps
    end

    create_join_table :cases, :cluster_logs
  end
end
