class AddTokenToCases < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :token, :text, null: true
  end
end
