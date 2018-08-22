class AddUnixNameToComponentGroup < ActiveRecord::Migration[5.2]
  def change
    add_column :component_groups, :unix_name, :string
    add_index :component_groups, :unix_name
  end
end
