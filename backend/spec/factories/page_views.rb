FactoryBot.define do
  factory :page_view do
    path { "/" }
    user_agent { "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" }
    visitor_hash { SecureRandom.hex(16) }
    referrer { "https://google.com" }

    trait :home_page do
      path { "/" }
    end

    trait :projects_page do
      path { "/projects" }
    end

    trait :blog_page do
      path { "/blog" }
    end

    trait :no_referrer do
      referrer { nil }
    end
  end
end
