class CreateExpansions < ActiveRecord::Migration[5.1]
  def change
    create_table :expansions do |t|
      t.string :slot, null:false
      t.integer :ports, null:false
      t.references :expansion_type, foreign_key: true, null:false
      t.string :type, null:false

      t.timestamps
    end
  end
end
