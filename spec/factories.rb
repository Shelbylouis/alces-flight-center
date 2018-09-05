
FactoryBot.define do

  factory :case_state_transition do
    association :case
    association :user, factory: :admin
    event 'resolve'
    from 'open'
    to 'resolved'
  end

  factory :case_comment do
    association :user, factory: :admin
    association :case # Avoid conflict with case keyword.
    text 'This is a comment'

    factory :case_comment_with_markdown_text do
      text "# Text title\n\nText body\n\n - Text list item 1\n"
    end
  end

  sequence :email do |n|
    "a.scientist.#{n}@liverpool.ac.uk"
  end

  factory :site do
    name 'Liverpool University'
    identifier 'Something'
  end

  factory :additional_contact do
    site
    email
  end


  factory :component_group do
    cluster
    name 'nodes'
  end

  factory :category do
    name 'User management'
  end

  factory :service_type do
    name 'Some Service'

    factory :automatic_service_type do
      automatic true
    end
  end

  factory :log do
    details 'I am the factory default details'
    cluster
    association :engineer, factory: :admin

    factory :log_with_markdown_details do
      details "# Details title\n\nDetails body\n\n - Details list item 1\n"
    end
  end

  factory :change_motd_request do
    motd 'Some new MOTD'
    association :case # Avoid conflict with case keyword.
  end

  factory :change_motd_request_state_transition do
    change_motd_request
    to :applied
  end

  factory :credit_charge do
    amount 1
    association :user, factory: :admin
    association :case
  end

  factory :change_request do
    association :case
    description 'Change request details text'
    credit_charge 1
  end

  factory :change_request_state_transition do
    association :change_request
    association :user, factory: :admin
    event 'propose'
    from 'draft'
    to 'awaiting_authorisation'
  end

  factory :collated_case_association_audit do
    skip_create  # since this isn't an ActiveRecord model
    association :user
    created_at DateTime.now

    initialize_with {
      component = create(:component)
      new(
        user.id,
        created_at,
        [
          create(
            :audit,
            action: 'create',
            audited_changes: {
              'associated_element_type': 'Component',
              'associated_element_id': component.id,
            }
          )
        ]
      )
    }

  end

  factory :audit, class: Audited::Audit do
    association :user
    action :update
    audited_changes []
  end

  factory :topic do
    sequence(:title) {|n| "Topic #{n}" }

    factory :global_topic do
      scope 'global'
    end

    factory :site_topic do
      scope 'site'
      association :site, factory: :site
    end

    trait :with_articles do
      transient do
        num_articles { 1 }
      end

      after :create do |topic, evaluator|
        create_list :article, evaluator.num_articles, topic: topic
      end
    end
  end


  factory :article do
    sequence(:title) {|n| "Article #{n}" }
    url { "http://some/url" }
    meta { { author: 'Alces Flight' } }
    association :topic, factory: :global_topic
  end

  factory :service_plan do
    association :cluster
    start_date { '2018-01-01' }
    end_date { '2020-12-30' }
  end
end
