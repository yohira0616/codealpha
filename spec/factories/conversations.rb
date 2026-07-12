FactoryBot.define do
  factory :conversation do
    project
    status { "pending" }
  end
end
