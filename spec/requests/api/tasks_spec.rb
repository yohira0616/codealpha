require "rails_helper"

RSpec.describe "Api::Tasks" do
  describe "PATCH /api/tasks/:id" do
    let(:project) { create(:project, name: "案件") }
    let(:task) do
      create(:task, project:, title: "T1",
        estimated_days: 2.0, estimated_price: 100000, estimated_by: "llm")
    end

    context "estimated_days を更新した場合" do
      it "estimated_by が user になる" do
        patch api_task_path(task), params: { task: { estimated_days: 5.0 } }, as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body["task"]
        expect(json).to include("estimated_days" => 5.0, "estimated_by" => "user")
      end
    end

    context "title だけを更新した場合" do
      it "estimated_by は変わらない" do
        patch api_task_path(task), params: { task: { title: "改名" } }, as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body["task"]
        expect(json).to include("title" => "改名", "estimated_by" => "llm")
      end
    end

    context "tags を更新した場合" do
      it "タグが保存され、estimated_by は変わらず、初期スコープ合計から除外される" do
        patch api_task_path(task), params: { task: { tags: [ "スコープ外", "次期フェーズ" ] } }, as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body["task"]
        expect(json).to include(
          "tags" => [ "スコープ外", "次期フェーズ" ],
          "estimated_by" => "llm"
        )

        get api_project_path(project)
        project_json = response.parsed_body["project"]
        expect(project_json["total_estimated_price"]).to eq(100000)
        expect(project_json["in_scope_estimated_price"]).to eq(0)
        expect(project_json["in_scope_estimated_days"]).to eq(0.0)
      end
    end
  end
end
