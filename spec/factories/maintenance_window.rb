
FactoryBot.define do
  factory :maintenance_window do
    add_attribute(:case) { create(:case) } # Avoid conflict with case keyword.
    user { create(:admin) }
    created_at 7.days.ago

    # This could also be a Cluster or Service; but one of these must be
    # associated and is the item under maintenance.
    component do
      create(:component) unless cluster || service
    end

    factory :unconfirmed_maintenance_window {}

    factory :confirmed_maintenance_window do
      confirmed_by { create(:contact) }

      factory :closed_maintenance_window do
        ended_at 3.days.ago
      end
    end
  end
end
