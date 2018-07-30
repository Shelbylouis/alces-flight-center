
FactoryBot.define do
  sequence :shortcode do |n|
    # Shortcodes must be unique and we create many clusters in tests
    "#{n}TEST"
  end

  factory :cluster do
    site
    name 'Hamilton Research Computing Cluster'
    support_type :managed
    shortcode
    motd 'My MOTD'

    factory :managed_cluster do
      support_type :managed
    end

    factory :advice_cluster do
      support_type :advice
    end
  end

  factory :credit_deposit do
    association :cluster
    association :user, factory: :admin
    amount 10
    effective_date Date.today
  end

  factory :check_category do
    name 'Generic Category Name'
  end

  factory :check do
    association :check_category
    name 'Check check testing 1 2 3'
    command 'Do the thing'
  end

  factory :cluster_check do
    association :check
    association :cluster
  end

  factory :check_result do
    association :cluster_check
    user
    date Date.today
    result 'Failure'
    comment 'Everything is fine'
  end
end
