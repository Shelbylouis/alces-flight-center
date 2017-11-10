class AddFileSystemQuotaIssue < ActiveRecord::DataMigration
  def up
    category = CaseCategory.find_by_name('Quota/Fair Usage Management')
    service_type = ServiceType.find_by_name('File System')
    raise unless category && service_type

    Issue.create!(
      case_category: category,
      name: 'File System storage quota changes',
      support_type: 'managed',
      requires_service: true,
      service_type: service_type,
      details_template: <<-EOF.squish
        Please give details of the storage quota changes you require.
      EOF
    )
  end
end
