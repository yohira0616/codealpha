class Project < ApplicationRecord
  has_many :conversations, dependent: :destroy
  has_many :tasks, dependent: :destroy

  validates :name, presence: true
  validates :daily_rate, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # タスクの見積もり人日の合計(未入力は除外)
  def total_estimated_days
    tasks.sum(0.0) { |t| t.estimated_days.to_f }
  end

  # タスクの見積もり金額の合計(nil は 0 扱い)
  def total_estimated_price
    tasks.sum { |t| t.estimated_price.to_i }
  end
end
