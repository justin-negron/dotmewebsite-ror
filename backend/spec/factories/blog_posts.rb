FactoryBot.define do
  factory :blog_post do
    sequence(:title) { |n| "Blog Post #{n}" }
    sequence(:slug) { |n| "blog-post-#{n}" }
    content { "This is a great blog post with lots of interesting content about technology and development." }
    excerpt { "This is a great blog post..." }
    published { false }
    published_at { nil }
    tags { ["Rails", "Ruby", "Development"] }
    view_count { 0 }
    
    trait :published do
      published { true }
      published_at { 1.week.ago }
    end
    
    trait :draft do
      published { false }
      published_at { nil }
    end
  end
end
