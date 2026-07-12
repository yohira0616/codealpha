module Api
  class MessagesController < BaseController
    include Serialization

    # 応答待ち(pending/running)がこの時間を超えていたらワーカー死亡等とみなし、
    # 投稿を受け付けて仕切り直す(CLIタイムアウト600秒より長くとる)
    STALE_AFTER = 15.minutes

    # POST /api/conversations/:conversation_id/messages 発言追加 → ジョブ投入
    def create
      conversation = Conversation.find(params[:conversation_id])
      content = params.require(:content).to_s

      # check-then-act の競合を避けるため、状態遷移を UPDATE の行数で判定する。
      # completed/failed、または長時間固まった pending/running のみ 1 行更新される。
      claimed = Conversation.where(id: conversation.id)
                            .where("status IN ('completed', 'failed') OR updated_at < ?", STALE_AFTER.ago)
                            .update_all(status: "pending", updated_at: Time.current)
      if claimed.zero?
        return render json: { error: "応答待ちです" }, status: :unprocessable_content
      end

      conversation.reload
      conversation.messages.create!(role: "user", content:)
      ConversationReplyJob.perform_later(conversation.id)

      render json: { conversation: conversation_detail_json(conversation) }, status: :created
    end
  end
end
