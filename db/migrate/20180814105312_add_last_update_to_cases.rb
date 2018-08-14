class AddLastUpdateToCases < ActiveRecord::Migration[5.2]
  def change
    add_column :cases, :last_update, :datetime, null: true
  end
end
