class AddConsultancyIssuesToOtherCategories < ActiveRecord::DataMigration
  def up
    # This data migration is obsolete with new changes to remove CaseCategorys,
    # make Services top-level etc, combined with simplifying of consultancy
    # Issues.
    return

    requested_categories = {
      'Application Management' => {},
      'End User Assistance' => {},
      'File System Quota Management' => {
        requires_service: true,
        service_type: ServiceType.find_by_name!('File System'),
      },
      'Queue Configuration' => {},
      'Queue Quota Management' => {},
      'Suspected Hardware Issue' => {
        requires_component: true
      },
      'Suspected Service Issue' => {
        requires_service: true
      },
      'User Management' => {},
    }

    requested_categories.each do |category_name, issue_params|
      category = CaseCategory.find_by_name!(category_name)
      category.issues.create!(
        name: 'Request custom consultancy',
        support_type: 'advice',
        details_template: 'Please describe the specialist support you would like to request from Alces Software.',
        **issue_params
      )
    end
  end
end
