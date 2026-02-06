FactoryBot.define do
  factory :experience do
    sequence(:company) { |n| "Company #{n}" }
    sequence(:position) { |n| "Position #{n}" }
    start_date { 2.years.ago.to_date }
    end_date { 1.year.ago.to_date }
    description { "Worked on various projects and technologies" }
    technologies { ["Ruby", "JavaScript", "PostgreSQL"] }
    sequence(:display_order)
    
    trait :current do
      end_date { nil }
    end
    
    trait :past do
      end_date { 1.year.ago.to_date }
    end
  end
end
