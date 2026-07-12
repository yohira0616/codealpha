require "rails_helper"

RSpec.describe ConversationReplyJob do
  let(:project) { create(:project, name: "案件", requirement_text: "ECサイトを作りたい", daily_rate: 50000) }
  let(:conversation) { create(:conversation, project:, status: "pending") }

  before do
    create(:message, conversation:, role: "user", content: "タスクを洗い出して")
  end

  describe "#perform" do
    context "CLI が成功した場合" do
      let(:text) do
        "承知しました。\n```json\n{\"tasks\": [{\"title\": \"商品CRUD\", \"estimated_days\": 3.0}]}\n```"
      end

      it "assistant 応答を保存し、タスクを同期し、session_id を保存して completed にする" do
        allow(ClaudeCli).to receive(:run).and_return({ text:, session_id: "sess-1" })

        described_class.perform_now(conversation.id)

        expect(ClaudeCli).to have_received(:run).with(
          prompt: include("ECサイトを作りたい")
            .and(include("タスクを洗い出して"))
            # references/*.md が注入され、プレースホルダが残っていないこと
            .and(include("## 参照資料:"))
            .and(satisfy { |p| !p.include?("%{references}") && !p.include?("%{requirement}") }),
          session_id: nil
        )
        conversation.reload
        expect(conversation.status).to eq("completed")
        expect(conversation.claude_session_id).to eq("sess-1")
        expect(conversation.messages.where(role: "assistant").sole.content).to eq(text)

        task = project.tasks.sole
        expect(task.title).to eq("商品CRUD")
        expect(task.estimated_price).to eq(150000)
      end
    end

    context "CLI が失敗した場合" do
      it "failed になり、セッションを破棄し、例外は再送出されない" do
        conversation.update!(claude_session_id: "sess-old")
        allow(ClaudeCli).to receive(:run).and_raise(ClaudeCli::Error, "boom")

        expect { described_class.perform_now(conversation.id) }.not_to raise_error
        conversation.reload
        expect(conversation.status).to eq("failed")
        # 次回投稿でテンプレート込みの新規セッションから再開できるようにする
        expect(conversation.claude_session_id).to be_nil
      end
    end

    context "応答にタスクJSONが無い場合" do
      it "応答は保存しつつ failed にして再送を促す(session_id は保持)" do
        allow(ClaudeCli).to receive(:run).and_return({ text: "JSONなしの応答", session_id: "sess-1" })

        described_class.perform_now(conversation.id)

        conversation.reload
        expect(conversation.status).to eq("failed")
        expect(conversation.claude_session_id).to eq("sess-1")
        expect(conversation.messages.where(role: "assistant").sole.content).to eq("JSONなしの応答")
      end
    end

    context "2通目以降(セッションあり)の場合" do
      it "最新の user メッセージのみ渡し、--resume 用に session_id を使う" do
        conversation.update!(claude_session_id: "sess-1")
        create(:message, conversation:, role: "assistant", content: "前回の応答")
        create(:message, conversation:, role: "user", content: "認証も追加して")
        allow(ClaudeCli).to receive(:run).and_return({ text: "了解\n```json\n{\"tasks\": []}\n```", session_id: "sess-1" })

        described_class.perform_now(conversation.id)

        expect(ClaudeCli).to have_received(:run).with(prompt: "認証も追加して", session_id: "sess-1")
        expect(conversation.reload.status).to eq("completed")
      end
    end

    context "初回失敗後の再送(userメッセージ複数・セッションなし)の場合" do
      it "テンプレート+要件テキストを含めて組み立て直す" do
        create(:message, conversation:, role: "user", content: "もう一度お願いします")
        allow(ClaudeCli).to receive(:run).and_return({ text: "```json\n{\"tasks\": []}\n```", session_id: "sess-2" })

        described_class.perform_now(conversation.id)

        expect(ClaudeCli).to have_received(:run).with(
          prompt: include("ECサイトを作りたい").and(include("もう一度お願いします")),
          session_id: nil
        )
      end
    end

    context "pending 以外の状態の場合" do
      it "二重実行を防ぐため何もしない" do
        conversation.update!(status: "running")
        allow(ClaudeCli).to receive(:run)

        described_class.perform_now(conversation.id)

        expect(ClaudeCli).not_to have_received(:run)
        expect(conversation.reload.status).to eq("running")
      end
    end
  end
end
