# claude -p を非同期実行して assistant 応答を保存し、タスクを同期するジョブ。
class ConversationReplyJob < ApplicationJob
  queue_as :default

  # prompts/task_breakdown.md が未作成の場合の代替指示
  FALLBACK_INSTRUCTION = <<~TEXT
    あなたはソフトウェア開発の見積もり担当者です。
    以下の要件から作成すべき機能・タスクを詳細に洗い出し、
    応答の最後に ```json フェンスで
    {"tasks": [{"title": "...", "description": "...", "category": "...", "estimated_days": 数値}]}
    形式のJSONを出力してください。

    要件:
    %{requirement}
  TEXT

  def perform(conversation_id)
    # pending → running をアトミックに1本だけ通し、二重enqueue時の並行実行を防ぐ
    claimed = Conversation.where(id: conversation_id, status: "pending")
                          .update_all(status: "running", updated_at: Time.current)
    return if claimed.zero?

    conversation = Conversation.find(conversation_id)

    result = ClaudeCli.run(
      prompt: build_prompt(conversation),
      session_id: conversation.claude_session_id
    )

    # 後続処理(保存・タスク同期)で例外が出ても対話の文脈を失わないよう、
    # session_id は応答取得直後に保存する
    conversation.update!(claude_session_id: result[:session_id])
    conversation.messages.create!(role: "assistant", content: result[:text])
    synced = TaskSync.call(conversation:, text: result[:text])
    # タスクJSONを取り出せなかった場合は failed にして再送を促す(応答自体は保存済み)
    conversation.update!(status: synced ? "completed" : "failed")
  rescue ClaudeCli::Error => e
    # CLI失敗(タイムアウト・セッション消失等)はセッションを破棄し、
    # 次回投稿でテンプレート+要件込みの新規セッションから再開できるようにする
    Rails.logger.error("[ConversationReplyJob] conversation=#{conversation_id} #{e.class}: #{e.message}")
    conversation&.update(status: "failed", claude_session_id: nil)
  rescue StandardError => e
    # 失敗しても対話自体は壊さない(ログのみで re-raise しない)
    Rails.logger.error("[ConversationReplyJob] conversation=#{conversation_id} #{e.class}: #{e.message}")
    conversation&.update(status: "failed")
  end

  private

  def build_prompt(conversation)
    latest = conversation.messages.where(role: "user").order(:id).last&.content.to_s

    # セッションがあれば --resume で文脈が保たれるため最新メッセージのみ渡す。
    # セッションが無い場合(初回、または初回失敗後の再送)は常にテンプレート+要件から組み立てる
    return latest if conversation.claude_session_id.present?

    template = load_template
    substitutions = {
      "requirement" => conversation.project.requirement_text.to_s,
      "references" => references_text
    }
    # 単一パスの gsub で置換する(挿入したテキストが再走査されず、要件文中の %{...} も無害)
    template.gsub(/%\{(requirement|references)\}/) { substitutions[Regexp.last_match(1)] } +
      "\n\n---\n\n" + latest
  end

  def load_template
    path = Rails.root.join("prompts/task_breakdown.md")
    path.exist? ? path.read : FALLBACK_INSTRUCTION
  end

  # references/ 直下の md を見積もりの参照データとしてプロンプトに注入する
  def references_text
    files = Rails.root.join("references").glob("*.md").sort
    return "(参照データなし)" if files.empty?

    files.map { |f| "## 参照資料: #{f.basename(".md")}\n\n#{f.read}" }.join("\n\n")
  end
end
