class AddAdministrativeIssue < ActiveRecord::Migration[5.2]

  ADMIN_ISSUE_NAME = 'Administrative'.freeze

  def up
    Issue.reset_column_information
    issue = Issue.create!(
      name: ADMIN_ISSUE_NAME,
      administrative: true,
      requires_component: false,
      requires_service: false,
      service_type: nil
    )

    tier = issue.tiers.first
    tier.level = 2
    tier.save!
  end

  def down
    Issue.find_by_name(ADMIN_ISSUE_NAME).destroy!
  end
end
