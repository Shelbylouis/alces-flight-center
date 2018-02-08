
FactoryBot.define do
  factory :cluster_log do
    
  end
  sequence :email do |n|
    "a.scientist.#{n}@liverpool.ac.uk"
  end

  factory :site do
    name 'Liverpool University'
  end

  factory :user do
    site
    name 'A Scientist'
    email
    password 'definitely_encrypted'

    factory :contact do
      admin false

      factory :primary_contact do
        primary_contact true
      end

      factory :secondary_contact do
        primary_contact false
      end
    end

    factory :admin do
      admin true
      site nil
    end
  end

  factory :additional_contact do
    site
    email
  end

  factory :component_type do
    name 'server'
    ordering 5
  end

  factory :component_make do
    component_type
    manufacturer 'manufacturer'
    model 'model'
    knowledgebase_url 'knowledgebase_url'
  end

  factory :component_group do
    cluster
    component_make
    name 'nodes'
  end

  factory :expansion_type do
    name 'switch'
  end

  factory :default_expansion do
    expansion_type
    component_make
    ports 4
    slot 'a'
  end

  factory :category do
    name 'User management'
  end

  factory :asset_record_field_definition, aliases: [:definition] do
    field_name 'Manufacturer/model name'
    level :group
    data_type 'short_text'
  end

  factory :service_type do
    name 'Some Service'

    factory :automatic_service_type do
      automatic true
    end
  end

  factory :credit_deposit do
    cluster
    user { create(:admin) }
    amount 10
  end

  factory :credit_charge do
    add_attribute(:case) { create(:case) } # Avoid conflict with case keyword.
    user { create(:admin) }
    amount 2
  end
end
