
FactoryBot.define do
  factory :issue do
    name 'New user/group'
    requires_component false

    factory :advice_issue do
    end

    factory :issue_requiring_component do
      requires_component true

      factory :request_component_becomes_advice_issue do
        identifier Issue::IDENTIFIERS.request_component_becomes_advice
        tiers { [create(:level_1_tier)] }
      end

      factory :request_component_becomes_managed_issue do
        identifier Issue::IDENTIFIERS.request_component_becomes_managed
        tiers { [create(:level_1_tier)] }
      end
    end

    factory :issue_requiring_service do
      requires_service true

      factory :request_service_becomes_advice_issue do
        identifier Issue::IDENTIFIERS.request_service_becomes_advice
        tiers { [create(:level_1_tier)] }
      end

      factory :request_service_becomes_managed_issue do
        identifier Issue::IDENTIFIERS.request_service_becomes_managed
        tiers { [create(:level_1_tier)] }
      end
    end

    factory :special_issue do
      identifier Issue::IDENTIFIER_NAMES.first
    end
  end
end
