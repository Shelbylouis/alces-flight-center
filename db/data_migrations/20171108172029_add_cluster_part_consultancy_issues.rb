class AddClusterPartConsultancyIssues < ActiveRecord::DataMigration
  def up
    category = Category.find_by_name('Consultancy')

    existing_issue = category.issues.first
    existing_issue.name = consultancy_issue_text('cluster')
    existing_issue.save!

    new_issue_attributes = {
      support_type: 'advice',
      details_template: existing_issue.details_template
    }

    category.issues.create!(
      **new_issue_attributes,
      name: consultancy_issue_text('component'),
      requires_component: true
    )

    category.issues.create!(
      **new_issue_attributes,
      name: consultancy_issue_text('service'),
      requires_service: true
    )
  end

  private

  def consultancy_issue_text(model_name)
    "Request custom consultancy for #{model_name}"
  end
end
