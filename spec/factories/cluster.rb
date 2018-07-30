
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
  end
end
