
FactoryBot.define do
  factory :case do
    issue
    cluster
    user
    fields [{name: 'Details', value: 'some_details'}]
    tier_level 3

    factory :open_case do
      state 'open'
    end

    factory :resolved_case do
      state 'resolved'
      time_worked 42
    end

    factory :closed_case do
      state 'closed'
      time_worked 42

      before(:create) do |k|
        if k.credit_charge.nil?
          k.credit_charge = build(:credit_charge, case: k)
        end
      end
    end

    factory :case_with_change_motd_request do
      change_motd_request
      fields nil
    end

    # Every Case requires a Cluster, so this is just the same as the standard
    # `case` factory; this is useful though to allow us to handle creating a
    # Case requiring each type of part in the same way.
    factory :case_requiring_cluster do
    end

    factory :case_requiring_component do
      association :issue, factory: :issue_requiring_component

      after :build do |instance|
        unless instance.components.empty?
          instance.cluster = instance.components.first.cluster
        end
      end

      factory :case_with_component do

        after :build do |instance|
          instance.components << build(:component, cluster: instance.cluster)
        end
      end
    end

    factory :case_requiring_service do
      association :issue, factory: :issue_requiring_service

      after :build do |instance|
        unless instance.services.empty?
          instance.cluster = instance.services.first.cluster
        end
      end

      factory :case_with_service do
        service

        after :build do |instance|
          instance.cluster = instance.services[0].cluster
        end
      end
    end
  end
end
