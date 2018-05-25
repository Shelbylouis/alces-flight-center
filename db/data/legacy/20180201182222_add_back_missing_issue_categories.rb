class AddBackMissingIssueCategories < ActiveRecord::DataMigration
  def up
    app_management = Category.find_by_name!('Application Management')
    end_user_assistance = Category.find_by_name!('End User Assistance')

    [
      'Custom open-source',
      'Custom commercial',
      'From available Alces Gridware',
    ].each do |name|
      Issue.find_by_name!(name).update!(category: app_management)
    end

    [
      'Self application install assistance',
      'Application problems/bugs',
      'Job running how-to/assistance',
      'Job script how-to/assistance',
      'Problem jobs',
    ].each do |name|
      Issue.find_by_name!(name).update!(category: end_user_assistance)
    end
  end
end
