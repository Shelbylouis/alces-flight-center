class AddConfirmationTokenToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :confirmation_token, :string, limit: 128
  end
end
