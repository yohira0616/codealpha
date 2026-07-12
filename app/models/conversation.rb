class Conversation < ApplicationRecord
  belongs_to :project
  has_many :messages, dependent: :destroy
  has_many :tasks, dependent: :nullify

  enum :status, {
    pending: "pending",
    running: "running",
    completed: "completed",
    failed: "failed"
  }, validate: true
end
