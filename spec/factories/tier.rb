
FactoryBot.define do
  factory :tier do
    issue
    level 2
    fields [{
      type: 'input',
      name: 'some_field',
      value: 'some_value',
    }]

    factory :level_1_tier do
      level 1

      factory :tier_with_tool do
        tool :motd
        fields { nil }
      end
    end
  end
end
