
FactoryGirl.define do
  factory :site do
    name 'Liverpool University'
  end

  factory :user do
    site
    name 'A Scientist'
    email 'a.scientist@liverpool.ac.uk'
    password 'definitely_encrypted'

    factory :contact do
      admin false
    end
  end

  factory :additional_contact do
    site
    email 'additional.contact@example.com'
  end

  factory :cluster do
    site
    name 'Hamilton Research Computing Cluster'
    support_type :managed

    factory :managed_cluster do
      support_type :managed
    end

    factory :advice_cluster do
      support_type :advice
    end
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
    support_type :inherit

    factory :managed_component do
      support_type :managed
    end

    factory :advice_component do
      support_type :advice
    end
  end

  factory :case_category do
    name 'User management'
  end

  factory :issue do
    case_category
    name 'New user/group'
    requires_component false
    details_template 'Enter the usernames to create'
    support_type :managed

    factory :advice_issue do
      support_type :advice
    end
  end

  factory :case do
    issue
    cluster
    user
    details "Oh no, my science isn't working"
    rt_ticket_id 12345
  end

  factory :asset_record_field_definition do
    field_name 'Manufacturer/model name'
    level :group
  end

  factory :unassociated_asset_record_field, class: AssetRecordField do
    asset_record_field_definition
    value ''
  end

  factory :service_type do
    name 'Some Service'

    factory :automatic_service_type do
      automatic true
    end
  end
end
