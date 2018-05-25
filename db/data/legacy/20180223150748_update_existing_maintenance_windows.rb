class UpdateExistingMaintenanceWindows < ActiveRecord::DataMigration
  def up
    MaintenanceWindow.all.each do |window|
      window.legacy_migration_mode = true

      # Change the state to `new` (from `requested`, what the default was set
      # to when this column was created) so we can simulate the new maintenance
      # request process.
      window.state = :new

      # Set `requested_start` and `duration` to plausible values; do this now
      # so model is valid.
      # Requested start can be considered to be whenever we requested the
      # maintenance, since it would have started immediately in the past.
      window.requested_start = window.created_at

      # Approximate `duration` as the number of business days between the
      # actual start and either the actual end or 2 weeks from now (if
      # maintenance has not yet ended). This will not be absolutely exact for
      # what really happened, as maintenance used to be able to be any length
      # but now must be an exact number of days, but is probably/hopefully more
      # than sufficient for our purposes.
      end_date_to_use =
        window.ended_at_legacy || DateTime.current.advance(weeks: 2)
      approximate_duration =
        window.requested_start.to_date.business_days_until(end_date_to_use)
      window.duration = approximate_duration

      window.save!

      # Simulate requesting maintenance.
      original_requestor = User.find(window.requested_by_id_legacy)
      window.request!(original_requestor)

      # Move onto next window, this one has only been requested.
      next unless window.confirmed_by_id_legacy

      # Simulate confirming maintenance.
      original_confirmer = User.find(window.confirmed_by_id_legacy)
      window.confirm!(original_confirmer)

      # Simulate starting this window if needed, if this should have already
      # happened.
      ProgressMaintenanceWindow.new(window).progress

      # We didn't previously track maintenance request, confirmation, or start
      # times (note that the latter two would have been the same previously).
      # Therefore just set all these transitions to have occurred at the
      # maintenance window creation time; this will be inaccurate for some of
      # these but is as good as any other arbitrary time we might pick.
      MaintenanceWindowStateTransition
        .where(maintenance_window: window)
        .update_all(created_at: window.created_at)

      # Simulate ending this window if needed, if this should have already
      # happened.
      ProgressMaintenanceWindow.new(window).progress

      # Move onto the next window, this one is still in progress.
      next unless window.ended?

      # Update the time this window ended to the recorded ended at time.
      MaintenanceWindowStateTransition
        .find_by!(maintenance_window_id: window.id, to: :ended)
        .update!(created_at: window.ended_at_legacy)
    end
  end
end
