FactoryBot.define do
  factory :contact do
    name { "John Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    subject { "Test Subject" }
    message { "This is a test message with enough content to pass validation." }
    status { "new" }
    
    trait :read do
      status { "read" }
    end
    
    trait :archived do
      status { "archived" }
    end
  end
end
