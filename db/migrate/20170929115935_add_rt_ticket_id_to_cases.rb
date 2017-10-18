class AddRtTicketIdToCases < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :rt_ticket_id, :integer, limit: 8
    add_index :cases, :rt_ticket_id, unique: true
  end
end
