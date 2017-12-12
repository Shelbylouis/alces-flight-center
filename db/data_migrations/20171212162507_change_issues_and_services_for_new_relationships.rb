class ChangeIssuesAndServicesForNewRelationships < ActiveRecord::DataMigration
  def up
    # Existing service types.
    user_management = ServiceType.find_by_name('User Management')
    workload_scheduler_management = ServiceType.find_by_name('Workload Scheduler Management')
    hpc_environment = ServiceType.find_by_name('HPC Environment')
    filesystem = ServiceType.find_by_name('File System')

    # New service type for Issues related to Cluster hardware.
    hardware = ServiceType.create!(name: 'Hardware', automatic: true)

    # Add new automatic Service to all existing Clusters.
    Cluster.all.each do |cluster|
      cluster.services.create!(name: hardware.name, service_type: hardware)
    end

    # This Issue was added in a now otherwise obsolete data migration
    # (db/data_migrations/20171109152749_adapt_case_categories_for_controlling_service_types.rb)
    # so may not exist locally, though it should exist in production, so create
    # it if it doesn't.
    queue_config_issue = 'Discuss alterations to queue configuration'
    unless Issue.find_by_name(queue_config_issue)
      Issue.create!(
        name: queue_config_issue,
        support_type: 'managed',
        details_template: 'TODO Add details template'
      )
    end

    # Set ServiceType each Issue should be associated with (or nil for any).
    issue_names_to_service_types = {
      'Hardware issue' => hardware,
      'Service issue' => nil,
      'Relinquish self-management of service' => nil,
      'Request self-management of service' => nil,
      'Request custom consultancy for service' => nil,
      'Additional users/groups' => user_management,
      'Discuss alterations to queue configuration' => workload_scheduler_management,
      'Scheduler changes' => workload_scheduler_management,
      'File System storage quota changes' => filesystem,
      'Custom commercial' => hpc_environment,
      'Custom open-source' => hpc_environment,
      'From available Alces Gridware' => hpc_environment,
      'Self application install assistance' => hpc_environment,
      'Application problems/bugs' => hpc_environment,
      'Job script how-to/assistance' => hpc_environment,
      'Job running how-to/assistance' => hpc_environment,
      'Problem jobs' => hpc_environment,
    }

    issue_names_to_service_types.each do |issue_name, service_type|
      Issue.find_by_name(issue_name).update!(
        requires_service: true,
        service_type: service_type
      )
    end
  end
end
