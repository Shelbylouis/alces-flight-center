
FactoryGirl.define do
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
end
