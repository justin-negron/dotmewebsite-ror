FactoryBot.define do
  factory :experience do
    company { "MyString" }
    position { "MyString" }
    start_date { "2026-01-25" }
    end_date { "2026-01-25" }
    description { "MyText" }
    technologies { "MyText" }
    display_order { 1 }
  end
end
