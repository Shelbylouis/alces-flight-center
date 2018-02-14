
FactoryBot.define do
  factory :maintenance_window do
    add_attribute(:case) { create(:case) } # Avoid conflict with case keyword.
    requested_by { create(:admin) }
    created_at 7.days.ago

    # This could also be a Cluster or Service; but one of these must be
    # associated and is the item under maintenance.
    component do
      create(:component) unless cluster || service
    end

    factory :requested_maintenance_window do
      state :requested
    end

    factory :confirmed_maintenance_window do
      state :confirmed
      confirmed_by { create(:contact) }

      factory :ended_maintenance_window do
        state :ended
        ended_at 3.days.ago
      end
    end
  end
end
