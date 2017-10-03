
FactoryGirl.define do
  factory :site do
    name 'Liverpool University'
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
end
