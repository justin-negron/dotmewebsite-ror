FactoryBot.define do
  factory :project do
    sequence(:title) { |n| "Project #{n}" }
    description { "A great project that does amazing things" }
    tech_stack { ["Ruby", "Rails", "PostgreSQL"] }
    github_url { "https://github.com/username/project" }
    live_url { "https://project.example.com" }
    featured { false }
    sequence(:display_order)
    
    trait :featured do
      featured { true }
    end
    
    trait :without_urls do
      github_url { nil }
      live_url { nil }
    end
  end
end
