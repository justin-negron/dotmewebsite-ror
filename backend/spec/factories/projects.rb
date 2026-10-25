FactoryBot.define do
  factory :project do
    sequence(:title) { |n| "Project #{n}" }
    description { "A great project that does amazing things" }
    tech_stack { [ "Ruby", "Rails", "PostgreSQL" ] }
    github_url { "https://github.com/username/project" }
    live_url { "https://project.example.com" }
    paper_url { nil }
    featured { false }
    media_urls { [] }
    sequence(:display_order)

    trait :featured do
      featured { true }
    end

    trait :with_media do
      media_urls { [ "https://cdn.example.com/one.webp", "https://cdn.example.com/two.webp" ] }
    end

    trait :without_urls do
      github_url { nil }
      live_url { nil }
    end
  end
end
