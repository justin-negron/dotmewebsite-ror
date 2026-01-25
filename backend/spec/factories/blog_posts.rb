FactoryBot.define do
  factory :blog_post do
    title { "MyString" }
    slug { "MyString" }
    content { "MyText" }
    excerpt { "MyText" }
    published { false }
    published_at { "2026-01-25 15:49:28" }
    tags { "MyText" }
    view_count { 1 }
  end
end
