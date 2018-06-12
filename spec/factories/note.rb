FactoryBot.define do
  factory :note do
    cluster
    description "# Description title\n\nDescription body\n"
    flavour { Note::FLAVOURS[rand(Note::FLAVOURS.length)] }

    factory :customer_note do
      flavour :customer
    end

    factory :engineering_note do
      flavour :engineering
    end
  end
end
