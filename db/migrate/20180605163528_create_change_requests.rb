class CreateChangeRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :change_requests do |t|
      t.references :case, foreign_key: true
      t.string :state, default: 'draft', null: false
      t.string :description, null: false
      t.integer :credit_charge, null: false

      t.timestamps
    end
  end
end
