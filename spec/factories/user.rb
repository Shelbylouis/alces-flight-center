
FactoryBot.define do
  factory :user do
    site
    name 'A Scientist'
    email
    password 'definitely_encrypted'
    role :secondary_contact

    factory :contact do
      admin false

      factory :primary_contact do
        primary_contact true
      end

      factory :secondary_contact do
        primary_contact false
      end
    end

    factory :admin do
      admin true
      site nil
    end
  end
end
