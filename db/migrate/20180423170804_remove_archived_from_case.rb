class RemoveArchivedFromCase < ActiveRecord::Migration[5.1]
  def change
    remove_column :cases, :archived, :bool
  end
end
