class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :conversation

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true
end
