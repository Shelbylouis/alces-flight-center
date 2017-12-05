class ChangeConsultancyIssuesForSplitFromCaseForm < ActiveRecord::DataMigration
  def up
    consultancy_category = 'Consultancy'

    categories = CaseCategory.all.reject do |category|
      # Just want to keep consultancy issues in consultancy category.
      category.name == consultancy_category
    end

    categories.each do |category|
      category.issues.each do |issue|
        issue.destroy! if issue.name =~ /consultancy/
      end
    end

    # Add identifiers so can find needed consultancy issues.
    consultancy_issues = CaseCategory.find_by_name(consultancy_category).issues
    cluster_issue, component_issue, service_issue = *consultancy_issues

    cluster_issue.update!(identifier: 'cluster_consultancy')
    component_issue.update!(identifier: 'component_consultancy')
    service_issue.update!(identifier: 'service_consultancy')
  end
end
