class AddChangeMotdIssue < ActiveRecord::DataMigration
  def up
    end_user_assistance = Category.find_by_name!('End User Assistance')
    hpc_environment_type = ServiceType.find_by_name!('HPC Environment')
    issue = end_user_assistance.issues.create!(
      name: 'Request change of MOTD',
      # XXX Now junk field which is still required, will be able to be removed
      # once current staging changes deployed.
      support_type: 'managed',
      requires_service: true,
      service_type: hpc_environment_type,
    )
    issue.tiers.create!(
      level: 1,
      tool: 'motd',
    )
  end
end
