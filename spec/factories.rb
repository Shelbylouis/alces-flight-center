
FactoryGirl.define do
  factory :site do
    name 'Liverpool University'
  end

  factory :user do
    site
    name 'A Scientist'
    email 'a.scientist@liverpool.ac.uk'
    password 'definitely_encrypted'
  end

  factory :cluster do
    site
    name 'Hamilton Research Computing Cluster'
    support_type :managed
  end

  factory :component_type do
    name 'server'
  end

  factory :component_group do
    cluster
    component_type
    name 'nodes'
  end

  factory :component do
    component_group
    name 'node01'
  end

  factory :case_category do
    name 'User management'
  end

  factory :issue do
    case_category
    name 'New user/group'
    requires_component false
    details_template 'Enter the usernames to create'
  end

  factory :case do
    issue
    cluster
    user
    details "Oh no, my science isn't working"
    rt_ticket_id 12345
  end
end
