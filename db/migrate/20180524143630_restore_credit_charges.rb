class RestoreCreditCharges < ActiveRecord::Migration[5.1]
  def change
    create_table :credit_charges do |t|
      t.timestamps null: false

      t.references :case, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.integer :amount, null: false
    end

    rename_column :cases, :credit_charge, :legacy_credit_charge
  end
end
