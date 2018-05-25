
FactoryBot.define do
  factory :user do
    site
    name 'A Scientist'
    email
    password 'definitely_encrypted'
    role :secondary_contact

    factory :contact do
      admin false
      role :primary_contact

      factory :primary_contact do
        primary_contact true
        role :primary_contact
      end

      factory :secondary_contact do
        primary_contact false
        role :secondary_contact
      end
    end

    factory :admin do
      admin true
      role :admin
      site nil
    end
  end
end
