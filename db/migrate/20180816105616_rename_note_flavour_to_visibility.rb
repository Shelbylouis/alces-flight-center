class RenameNoteFlavourToVisibility < ActiveRecord::Migration[5.2]
  def change
    remove_index :notes, [:flavour, :cluster_id]
    rename_column :notes, :flavour, :visibility
  end
end
