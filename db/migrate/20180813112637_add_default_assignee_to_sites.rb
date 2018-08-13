class AddDefaultAssigneeToSites < ActiveRecord::Migration[5.2]
  def change
    add_reference :sites,
                  :default_assignee,
                  foreign_key: { to_table: :users },
                  null: true
  end
end
