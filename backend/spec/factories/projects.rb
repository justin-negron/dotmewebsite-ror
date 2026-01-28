FactoryBot.define do
  factory :project do
    title { "MyString" }
    description { "MyText" }
    tech_stack { "MyText" }
    github_url { "MyString" }
    live_url { "MyString" }
    image_url { "MyString" }
    featured { false }
    display_order { 1 }
  end
end
