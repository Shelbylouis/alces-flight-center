class AddMaintenanceEndingSoonEmailSentToMaintenanceWindows < ActiveRecord::Migration[5.2]
  def change
    add_column :maintenance_windows,
      :maintenance_ending_soon_email_sent,
      :boolean,
      default: false
  end
end
