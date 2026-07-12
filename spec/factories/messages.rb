FactoryBot.define do
  factory :message do
    conversation
    role { "user" }
    content { "テストメッセージ" }
  end
end
