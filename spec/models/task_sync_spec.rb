require "rails_helper"

RSpec.describe TaskSync do
  describe ".call" do
    let(:project) { create(:project, name: "テスト案件", daily_rate: 50000) }
    let(:conversation) { create(:conversation, project:, status: "completed") }

    def fenced(json)
      "タスクを洗い出しました。\n\n```json\n#{json}\n```\n"
    end

    context "応答に JSON ブロックが含まれる場合" do
      it "タスクを作成する(価格は 人日 × daily_rate)" do
        text = fenced('{"tasks": [{"title": "ログイン機能", "description": "認証まわり", "category": "認証", "estimated_days": 2.5}]}')

        expect(described_class.call(conversation:, text:)).to be(true)

        task = project.tasks.sole
        expect(task).to have_attributes(
          title: "ログイン機能",
          description: "認証まわり",
          category: "認証",
          estimated_price: 125000, # 2.5 × 50,000
          estimated_by: "llm",
          position: 0,
          conversation_id: conversation.id
        )
        expect(task.estimated_days.to_f).to eq(2.5)
      end
    end

    context "json フェンスが複数ある場合" do
      it "最後のブロックを使う" do
        text = fenced('{"tasks": [{"title": "古い"}]}') + "\n再考しました。\n" +
               fenced('{"tasks": [{"title": "新しい"}]}')

        expect(described_class.call(conversation:, text:)).to be(true)
        expect(project.tasks.pluck(:title)).to eq([ "新しい" ])
      end
    end

    context "user 編集済みタスクが title 一致する場合" do
      it "見積もりを保持したまま説明とカテゴリを更新する" do
        create(:task, project:,
          title: "ログイン機能", description: "旧説明", category: "その他",
          estimated_days: 9.0, estimated_price: 999_999, estimated_by: "user", position: 5)
        text = fenced('{"tasks": [{"title": "ログイン機能", "description": "新説明", "category": "認証", "estimated_days": 1.0}]}')

        expect(described_class.call(conversation:, text:)).to be(true)

        task = project.tasks.sole
        expect(task).to have_attributes(
          estimated_by: "user",
          estimated_price: 999_999,
          description: "新説明",
          category: "認証",
          position: 0
        )
        expect(task.estimated_days.to_f).to eq(9.0)
      end
    end

    context "新リストに対応の無いタスクがある場合" do
      it "llm タスクも user タスクも洗い替えで削除される" do
        create(:task, project:, title: "消えるLLMタスク", estimated_by: "llm")
        create(:task, project:, title: "消えるuserタスク", estimated_by: "user", estimated_days: 3.0)
        text = fenced('{"tasks": [{"title": "残るタスク", "estimated_days": 1.0}]}')

        expect(described_class.call(conversation:, text:)).to be(true)
        expect(project.tasks.pluck(:title)).to eq([ "残るタスク" ])
      end
    end

    context "JSON ブロックが無い場合" do
      it "false を返し何もしない" do
        create(:task, project:, title: "既存タスク")

        expect(described_class.call(conversation:, text: "JSONはありません")).to be(false)
        expect(project.tasks.count).to eq(1)
      end
    end

    context "JSON がパース不能な場合" do
      it "false を返す" do
        expect(described_class.call(conversation:, text: fenced('{"tasks": [壊れてる'))).to be(false)
      end
    end

    context "tasks キーが配列でない場合" do
      it "false を返す" do
        expect(described_class.call(conversation:, text: fenced('{"tasks": "not array"}'))).to be(false)
      end
    end

    context "tags が含まれる場合" do
      it "正規化して保存する(不正要素・重複・空白は除去)" do
        text = fenced('{"tasks": [{"title": "カレンダー連携", "estimated_days": 7, ' \
                      '"tags": ["スコープ外", " 次期フェーズ ", "スコープ外", "", 123, null]}]}')

        expect(described_class.call(conversation:, text:)).to be(true)
        task = project.tasks.sole
        expect(task.tags).to eq([ "スコープ外", "次期フェーズ" ])
        expect(task.in_scope?).to be(false)
      end

      it "user 編集済みタスクのタグは洗い替えで上書きしない" do
        create(:task, project:, title: "ログイン機能", estimated_by: "user", tags: [ "要確認" ])
        text = fenced('{"tasks": [{"title": "ログイン機能", "estimated_days": 1.0, "tags": ["スコープ外"]}]}')

        expect(described_class.call(conversation:, text:)).to be(true)
        expect(project.tasks.sole.tags).to eq([ "要確認" ])
      end
    end
  end
end
