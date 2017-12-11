class AdaptCaseCategoriesForControllingServiceTypes < ActiveRecord::DataMigration
  WORKLOAD_SCHEDULER_MANAGEMENT = ServiceType.find_by_name!('Workload Scheduler Management')

  def up
    # This data migration is obsolete with new changes to remove CaseCategorys,
    # make Services top-level etc.
    return

    alter_user_management_case_category
    add_queue_configuration_case_category
    replace_quota_management_case_category
    associate_hpc_environment_controlled_case_categories
  end

  private

  def alter_user_management_case_category
    case_category = CaseCategory.find_by_name!('User Management')
    service_type = ServiceType.find_by_name!('User Management')
    case_category.controlling_service_type = service_type
    case_category.save!
  end

  def add_queue_configuration_case_category
    CaseCategory.create!(
      name: 'Queue Configuration',
      controlling_service_type: WORKLOAD_SCHEDULER_MANAGEMENT
    ).tap do |category|
      category.issues.create!(
        name: 'Discuss alterations to queue configuration',
        support_type: 'managed',
        details_template: 'TODO Add details template'
      )
    end
  end

  def replace_quota_management_case_category
    existing_category = CaseCategory.find_by_name!('Quota/Fair Usage Management')

    queue_quota_category = CaseCategory.create!(
      name: 'Queue Quota Management',
      controlling_service_type: WORKLOAD_SCHEDULER_MANAGEMENT,
    )
    scheduler_changes_issue = existing_category.issues.find_by_name!(
      'Scheduler changes'
    )
    scheduler_changes_issue.case_category = queue_quota_category
    scheduler_changes_issue.save!

    filesystem_quota_category = CaseCategory.create!(
      name: 'File System Quota Management'
    )
    filesystem_quota_issue = existing_category.issues.find_by_name!(
      'File System storage quota changes'
    )
    filesystem_quota_issue.case_category = filesystem_quota_category
    filesystem_quota_issue.save!

    # Only issue should be 'Storage quota changes', which is superceded by
    # 'File System storage quota changes' and should be destroyed.
    raise unless existing_category.issues.length == 1
    existing_category.issues.first.destroy!

    existing_category.destroy!
  end

  def associate_hpc_environment_controlled_case_categories
    hpc_environment = ServiceType.find_by_name!('HPC Environment')

    application_management = CaseCategory.find_by_name!('Application Management')
    application_management.controlling_service_type = hpc_environment
    application_management.save!

    end_user_assistance = CaseCategory.find_by_name!('End User Assistance')
    end_user_assistance.controlling_service_type = hpc_environment
    end_user_assistance.save!
  end
end
