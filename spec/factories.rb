
FactoryBot.define do
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

    factory :admin do
      admin true
      site nil
    end
  end

  factory :additional_contact do
    site
    email 'additional.contact@example.com'
  end

  factory :component_type do
    name 'server'
  end

  factory :component_group do
    cluster
    component_type
    name 'nodes'
  end

  factory :case_category do
    name 'User management'
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
