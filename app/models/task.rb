class Task < ApplicationRecord
  belongs_to :project
  belongs_to :conversation, optional: true

  enum :estimated_by, { llm: "llm", user: "user" }, validate: true

  validates :title, presence: true
  validates :estimated_days, :estimated_price,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
