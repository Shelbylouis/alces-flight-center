class AddStatusToCases < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :status, :string, default: :open, null: false
  end
end
