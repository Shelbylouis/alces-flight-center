
FactoryGirl.define do
  factory :case do
    issue
    cluster
    user
    details "Oh no, my science isn't working"

    factory :case_with_component do
      association :issue, factory: :issue_requiring_component
      before :create do |instance|
        instance.component = create(:component)
        instance.cluster = instance.component.cluster
      end
    end

    factory :case_with_service do
      association :issue, factory: :issue_requiring_service
      before :create do |instance|
        instance.service = create(:service)
        instance.cluster = instance.service.cluster
      end
    end
  end
end
