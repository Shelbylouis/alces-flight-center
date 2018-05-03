class AddDisplayIdToCases < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :display_id, :string # We'd like this to be null: false but
    # can't until the field has been populated for existing cases.

    add_index :cases, :display_id, unique: true
  end
end
