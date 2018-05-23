class RemoveLastKnownTicketStatusFromCase < ActiveRecord::Migration[5.1]
  def change
    remove_column :cases, :last_known_ticket_status, :string, default: 'new'
  end
end
