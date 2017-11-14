class AddLastKnownTicketStatusToCases < ActiveRecord::Migration[5.1]
  def change
    add_column :cases,
      :last_known_ticket_status,
      :string,
      null: false,
      default: 'new'
  end
end
