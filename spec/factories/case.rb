
FactoryBot.define do
  factory :case do
    issue
    cluster
    user
    details "Oh no, my science isn't working"
    fields [{name: 'Details', value: 'some_details'}]
    tier_level 2

    factory :open_case do
      archived false
    end

    factory :archived_case do
      archived true
    end

    factory :case_requiring_component do
      association :issue, factory: :issue_requiring_component

      before :create do |instance|
        instance.cluster = instance.component&.cluster
      end

      factory :case_with_component do
        before :create do |instance|
          instance.component = create(:component)
          instance.cluster = instance.component.cluster
        end
      end
    end

    # XXX Very similar to above for Services.
    factory :case_requiring_service do
      association :issue, factory: :issue_requiring_service

      before :create do |instance|
        instance.cluster = instance.service&.cluster
      end

      factory :case_with_service do
        before :create do |instance|
          instance.service = create(:service)
          instance.cluster = instance.service.cluster
        end
      end
    end
  end
end
