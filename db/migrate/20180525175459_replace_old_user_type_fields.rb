class ReplaceOldUserTypeFields < ActiveRecord::Migration[5.2]
  def change
    change_column_null :users, :role, false

    remove_column :users, :admin, :boolean
    remove_column :users, :primary_contact, :boolean
  end
end
