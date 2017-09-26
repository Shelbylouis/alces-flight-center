class ChangeContactsForClearanceSupport < ActiveRecord::Migration[5.1]
  def change
    # Just drop and recreate table in format expected by Clearance (adjusted
    # for our use case, with our additional fields etc), so don't need to
    # handle migrating data since we don't care about this.
    drop_table :contacts {}
    create_table :contacts do |t|
      t.timestamps null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :encrypted_password, limit: 128, null: false
      t.string :remember_token, limit: 128, null: false
    end

    add_index :contacts, :email
    add_index :contacts, :remember_token
    add_reference :contacts, :site, foreign_key: true
  end
end
