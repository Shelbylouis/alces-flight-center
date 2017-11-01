
FactoryGirl.define do
  factory :service do
    service_type
    cluster
    name 'Instance of Some Service'
    support_type :inherit

    factory :managed_service do
      support_type :managed
    end

    factory :advice_service do
      support_type :advice
    end
  end
end
