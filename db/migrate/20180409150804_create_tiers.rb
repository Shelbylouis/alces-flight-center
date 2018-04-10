class CreateTiers < ActiveRecord::Migration[5.1]
  def change
    create_table :tiers do |t|
      t.timestamps null: false

      t.integer :level, null: false
      t.json :fields, null: false
      t.references :issue, null: false
    end

    add_column :cases, :tier_level, :integer
    add_column :cases, :fields, :json
  end
end
