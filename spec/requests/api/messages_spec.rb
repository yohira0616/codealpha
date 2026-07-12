require "rails_helper"

RSpec.describe "Api::Messages / Api::Conversations" do
  let(:project) { create(:project, name: "案件") }

  describe "POST /api/projects/:id/conversations" do
    it "対話を開始して応答ジョブを積む" do
      message = "この要件でタスクを洗い出してください。長いタイトルは切り詰められます。"

      expect {
        post api_project_conversations_path(project), params: { message: }, as: :json
      }.to have_enqueued_job(ConversationReplyJob)

      expect(response).to have_http_status(:created)
      json = response.parsed_body["conversation"]
      expect(json["title"]).to eq(message[0, 30])
      expect(json["status"]).to eq("pending")
      expect(json["messages"].sole["content"]).to eq(message)
    end
  end

  describe "POST /api/conversations/:id/messages" do
    context "対話が完了している場合" do
      it "user メッセージを保存して応答ジョブを積む" do
        conversation = create(:conversation, project:, status: "completed")

        expect {
          post api_conversation_messages_path(conversation), params: { content: "追加の質問" }, as: :json
        }.to have_enqueued_job(ConversationReplyJob)

        expect(response).to have_http_status(:created)
        expect(conversation.reload.status).to eq("pending")
      end
    end

    context "応答待ち(pending/running)の場合" do
      it "422 を返しメッセージもジョブも作らない" do
        conversation = create(:conversation, project:, status: "running")

        expect {
          post api_conversation_messages_path(conversation), params: { content: "割り込み" }, as: :json
        }.not_to have_enqueued_job

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["error"]).to eq("応答待ちです")
        expect(conversation.messages.count).to eq(0)
      end
    end

    context "応答待ちのまま長時間固まっている場合" do
      it "ワーカー死亡とみなして投稿を受け付け、仕切り直す" do
        conversation = create(:conversation, project:, status: "running")
        conversation.update_column(:updated_at, 16.minutes.ago)

        expect {
          post api_conversation_messages_path(conversation), params: { content: "再開したい" }, as: :json
        }.to have_enqueued_job(ConversationReplyJob)

        expect(response).to have_http_status(:created)
        expect(conversation.reload.status).to eq("pending")
      end
    end
  end
end
