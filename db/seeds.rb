
CaseCategory.create!(name: 'User Management').tap do |user_management|
  Issue.create!(
    name: 'Additional users/groups',
    case_category: user_management,
    details_template: <<-EOF.squish
      Please give the username, primary group, and any additional groups for
      each user to be created; give the name and any users which should be
      added for each group to be created.
    EOF
  )
end

CaseCategory.create!(name: 'Application Management').tap do |application_management|
  Issue.create!(
    name: 'From available Alces Gridware',
    case_category: application_management,
    details_template: <<-EOF.squish
      See https://gridware.alces-flight.com for the full directory of available
      Gridware; please give the package name and version of each Gridware
      package you would like installed.
    EOF

  )
  Issue.create!(
    name: 'Custom open-source',
    case_category: application_management,
    details_template: <<-EOF.squish
      Please give a URL where the open-source package to install can be found,
      and any special compilation settings or other additional details needed.
    EOF
  )
  Issue.create!(
    name: 'Custom commercial',
    case_category: application_management,
    details_template: <<-EOF.squish
      Please give a URL where the commercial package to install can be found,
      and any installation keys or other additional details needed.
    EOF
  )
end

CaseCategory.create!(name: 'Quota/Fair Usage Management').tap do |quota_management|
  Issue.create!(
    name: 'Storage quota changes',
    case_category: quota_management,
    details_template: <<-EOF.squish
      Please give details of the storage quota changes you require.
    EOF
  )
  Issue.create!(
    name: 'Scheduler changes',
    case_category: quota_management,
    details_template: <<-EOF.squish
      Please give details of the scheduler changes you require.
    EOF
  )
end

CaseCategory.create!(name: 'Suspected Hardware Issue').tap do |hardware|
  Issue.create!(
    name: 'Hardware issue',
    case_category: hardware,
    requires_component: true,
    details_template: <<-EOF.squish
      Please give as much additional information as possible about the
      suspected hardware issue.
    EOF
  )
end


CaseCategory.create!(name: 'End User Assistance').tap do |end_user_assistance|
  Issue.create!(
    name: 'Problem jobs',
    case_category: end_user_assistance,
    details_template: <<-EOF.squish
      Please give as much information as possible about the problem job.
    EOF

  )
  Issue.create!(
    name: 'Job running how-to/assistance',
    case_category: end_user_assistance,
    details_template: <<-EOF.squish
      Please give as much information as possible about the problems you are
      having running a job.
    EOF
  )
  Issue.create!(
    name: 'Job script how-to/assistance',
    case_category: end_user_assistance,
    details_template: <<-EOF.squish
      Please give as much information as possible about the problems you are
      having with your job script.
    EOF
  )
  Issue.create!(
    name: 'Application problems/bugs',
    case_category: end_user_assistance,
    details_template: <<-EOF.squish
      Please give as much information as possible about the application problem
      you are encountering .
    EOF
  )
  Issue.create!(
    name: 'Self application install assistance',
    case_category: end_user_assistance,
    details_template: <<-EOF.squish
      Please give as much information as possible about the application you are
      trying to install and the problem you are encountering.
    EOF
  )
end

CaseCategory.create!(name: 'Consultancy').tap do |consultancy|
  Issue.create!(
    name: 'Request custom consultancy',
    case_category: consultancy,
    details_template: <<-EOF.squish
      Please describe the specialist support you would like to request from
      Alces Software.
    EOF
  )
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
