
FactoryBot.define do
  factory :case do
    issue
    cluster
    user
    fields [{name: 'Details', value: 'some_details'}]
    tier_level 2
    sequence(:rt_ticket_id) { |n| n }

    factory :open_case do
      archived false
      state 'open'
    end

    factory :resolved_case do
      state 'resolved'
    end

    factory :archived_case do
      archived true
      state 'archived'
    end

    factory :case_requiring_component do
      association :issue, factory: :issue_requiring_component

      before :create do |instance|
        instance.cluster = instance.component&.cluster
      end

      factory :case_with_component do
        component

        before :create do |instance|
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
        service

        before :create do |instance|
          instance.cluster = instance.service.cluster
        end
      end
    end
  end
end
