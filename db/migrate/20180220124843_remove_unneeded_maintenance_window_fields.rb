class RemoveUnneededMaintenanceWindowFields < ActiveRecord::Migration[5.1]
  def change
    change_table :maintenance_windows do |t|
      reversible do |direction|
        direction.up do
          t.remove :requested_at, :confirmed_at, :started_at, :expired_at, :rejected_at, :cancelled_at
        end

        direction.down do
          t.timestamp :requested_at
          t.timestamp :confirmed_at
          t.timestamp :started_at
          t.timestamp :expired_at
          t.timestamp :rejected_at
          t.timestamp :cancelled_at
        end
      end

      t.remove_references :rejected_by
      t.remove_references :cancelled_by

      # Rename rather than remove these columns as we have important production
      # data we want to preserve in these columns for now.
      t.rename :ended_at, :ended_at_legacy
      t.rename :requested_by_id, :requested_by_id_legacy
      t.rename :confirmed_by_id, :confirmed_by_id_legacy
    end

    # For similar reasons this column is now nullable, since we want to
    # preserve it for existing records but not keep setting it for new records.
    change_column_null :maintenance_windows, :requested_by_id_legacy, true
  end
end
