
FactoryBot.define do
  factory :maintenance_window do
    add_attribute(:case) { create(:case) } # Avoid conflict with case keyword.
    created_at 7.days.ago
    requested_start 1.days.from_now.at_midnight
    duration 1

    # This could also be a Cluster or Service; but one of these must be
    # associated and is the item under maintenance.
    component do
      create(:component) unless cluster || service || associated_model
    end

    # For these factories to create a MaintenanceWindow in a particular state,
    # we create the window in a preceding state and then transition it to the
    # required state in a callback; this is done so the appropriate
    # MaintenanceWindowStateTransition is also created, which is sometimes
    # needed in tests.
    factory :requested_maintenance_window do
      state :new

      after(:create) do |window|
        window.request!(create(:admin))
      end
    end

    factory :confirmed_maintenance_window do
      state :requested

      after(:create) do |window|
        window.confirm!(create(:contact))
      end
    end

    factory :ended_maintenance_window do
      state :started

      after(:create) do |window|
        window.end!
      end
    end

    factory :expired_maintenance_window do
      state :requested

      after(:create) do |window|
        window.requested_start = 2.days.ago.at_midnight
        window.expire!
      end
    end
  end

  factory :maintenance_window_state_transition do
    maintenance_window
    to :requested
  end
end
