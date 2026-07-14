class Task < ApplicationRecord
  # 予約タグ: これが付いたタスクは「初期スコープ」の合計から除外される
  SCOPE_OUT_TAG = "スコープ外".freeze

  belongs_to :project
  belongs_to :conversation, optional: true

  enum :estimated_by, { llm: "llm", user: "user" }, validate: true

  validates :title, presence: true
  validates :estimated_days, :estimated_price,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :tags_must_be_string_array

  def in_scope?
    !tags.include?(SCOPE_OUT_TAG)
  end

  private

  def tags_must_be_string_array
    return if tags.is_a?(Array) && tags.all?(String)

    errors.add(:tags, "は文字列の配列で指定してください")
  end
end
