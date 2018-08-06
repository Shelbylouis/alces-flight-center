class CreateClusterCheck < ActiveRecord::Migration[5.2]
  def change
    create_table :cluster_checks do |t|
      t.references :cluster, null: false
      t.references :check, null: false
    end
  end
end
