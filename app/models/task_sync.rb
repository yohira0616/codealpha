# assistant 応答テキスト中の ```json ブロックからタスク一覧を取り出し、
# プロジェクトのタスクを洗い替え+マージする PORO。
class TaskSync
  JSON_FENCE = /```json\s*\n(.*?)```/m

  # 成功したら true、JSONブロックが無い・パース不能なら false を返す(例外にしない)。
  def self.call(conversation:, text:)
    new(conversation:, text:).call
  end

  def initialize(conversation:, text:)
    @conversation = conversation
    @project = conversation.project
    @text = text
  end

  def call
    new_tasks = extract_tasks
    return false if new_tasks.nil?

    sync!(new_tasks)
    true
  end

  private

  # 最後の ```json フェンスブロックを抽出して {"tasks": [...]} をパースする
  def extract_tasks
    block = @text.to_s.scan(JSON_FENCE).last&.first
    return nil if block.nil?

    parsed = JSON.parse(block)
    tasks = parsed["tasks"]
    return nil unless tasks.is_a?(Array)

    tasks
  rescue JSON::ParserError
    nil
  end

  def sync!(new_tasks)
    ActiveRecord::Base.transaction do
      # ユーザーが人日・価格を編集したタスクは title 一致で見積もりを保持する
      # (同名が複数あっても黙って消さないよう group で全件持つ)
      user_tasks = @project.tasks.where(estimated_by: "user").group_by(&:title)
      protected_ids = user_tasks.values.flatten.map(&:id)
      @project.tasks.where.not(id: protected_ids).destroy_all

      matched_ids = []
      new_tasks.each_with_index do |attrs, index|
        next unless attrs.is_a?(Hash)

        title = attrs["title"].to_s
        next if title.blank?

        if (existing = user_tasks[title]&.first)
          # ユーザー編集済み: 見積もり(人日・価格・estimated_by)は保持し、説明とカテゴリだけ更新
          existing.update!(
            description: attrs["description"],
            category: attrs["category"],
            position: index,
            conversation_id: @conversation.id
          )
          # 同名の user タスクは残りも削除対象から外す(黙って消さない)
          matched_ids.concat(user_tasks[title].map(&:id))
        else
          # DB の保存精度(scale: 1)に丸めてから価格を計算し、表示と価格の不整合を防ぐ
          days = attrs["estimated_days"]&.to_f&.round(1)
          @project.tasks.create!(
            conversation_id: @conversation.id,
            title:,
            description: attrs["description"],
            category: attrs["category"],
            estimated_days: days,
            estimated_price: days ? (days * @project.daily_rate).round : nil,
            estimated_by: "llm",
            position: index
          )
        end
      end

      # 新リストに対応が無くなったユーザー編集タスクも削除(洗い替え)
      @project.tasks.where(estimated_by: "user").where.not(id: matched_ids).destroy_all
    end
  end
end
