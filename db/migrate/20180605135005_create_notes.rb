class CreateNotes < ActiveRecord::Migration[5.2]
  def change
    create_table :notes do |t|
      t.text :description, null: false
      t.string :flavour, null: false, limit: 64

      t.references :cluster, foreign_key: true
      t.timestamps
    end

    add_index :notes, [:flavour, :cluster_id], unique: true
  end
end
