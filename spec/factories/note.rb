FactoryBot.define do
  factory :note do
    cluster
    description "# Description title\n\nDescription body\n"
    visibility { Note::VISIBILITIES.sample }

    factory :customer_note do
      visibility :customer
    end

    factory :engineering_note do
      visibility :engineering
    end
  end
end
