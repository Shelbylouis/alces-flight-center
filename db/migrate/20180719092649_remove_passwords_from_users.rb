class RemovePasswordsFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :encrypted_password, :string, limit: 128, null: false
  end
end
