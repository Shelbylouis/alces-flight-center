class RenameClusterLogToLog < ActiveRecord::Migration[5.1]
  def change
    rename_table :cluster_logs, :logs
    add_reference :logs, :component, foreign_key: true, null: true

    rename_table :cases_cluster_logs, :cases_logs
    rename_column :cases_logs, :cluster_log_id, :log_id
  end
end
