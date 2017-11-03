
FactoryGirl.define do
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
end
