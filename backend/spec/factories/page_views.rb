FactoryBot.define do
  factory :page_view do
    path { "MyString" }
    user_agent { "MyText" }
    ip_address { "" }
    referrer { "MyString" }
  end
end
