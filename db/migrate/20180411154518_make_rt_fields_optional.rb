class MakeRtFieldsOptional < ActiveRecord::Migration[5.1]
  def change
    change_column_null :cases, :rt_ticket_id, true
    change_column_null :cases, :last_known_ticket_status, true
  end
end
