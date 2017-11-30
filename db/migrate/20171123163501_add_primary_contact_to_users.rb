class AddPrimaryContactToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :primary_contact, :boolean, default: false
  end
end
