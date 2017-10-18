
CaseCategory.create!(name: 'User Management').tap do |user_management|
  Issue.create!(name: 'Additional users/groups', case_category: user_management)
end

CaseCategory.create!(name: 'Application Management').tap do |application_management|
  Issue.create!(name: 'From available Alces Gridware', case_category: application_management)
  Issue.create!(name: 'Custom open-source', case_category: application_management)
  Issue.create!(name: 'Custom commercial', case_category: application_management)
end

CaseCategory.create!(name: 'Quota/Fair Usage Management').tap do |quota_management|
  Issue.create!(name: 'Storage quota changes', case_category: quota_management)
  Issue.create!(name: 'Scheduler changes', case_category: quota_management)
end

CaseCategory.create!(name: 'Suspected Hardware Issue').tap do |hardware|
  Issue.create!(name: 'Hardware issue', case_category: hardware, requires_component: true)
end


CaseCategory.create!(name: 'End User Assistance').tap do |end_user_assistance|
  Issue.create!(name: 'Problem jobs', case_category: end_user_assistance)
  Issue.create!(name: 'Job running how-to/assistance', case_category: end_user_assistance)
  Issue.create!(name: 'Job script how-to/assistance', case_category: end_user_assistance)
  Issue.create!(name: 'Application problems/bugs', case_category: end_user_assistance)
  Issue.create!(name: 'Self application install assistance', case_category: end_user_assistance)
end

CaseCategory.create!(name: 'Consultancy').tap do |consultancy|
  Issue.create!(name: 'Request custom consultancy', case_category: consultancy)
end

ComponentType.create!(name: 'Server')
ComponentType.create!(name: 'Disk array')
ComponentType.create!(name: 'Network switch')

User.create!(
  name: 'Temporary admin',
  admin: true,
  email: 'admin@example.com',
  password: 'password'
)
