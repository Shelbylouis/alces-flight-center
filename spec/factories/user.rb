
FactoryBot.define do
  factory :user do
    site
    name 'A Scientist'
    email
    password 'definitely_encrypted'
    role :secondary_contact

    factory :viewer do
      role :viewer
    end

    factory :contact do
      role :secondary_contact

      factory :primary_contact do
        role :primary_contact
      end

      factory :secondary_contact do
        role :secondary_contact
      end
    end

    factory :admin do
      role :admin
      site nil
    end
  end
end
