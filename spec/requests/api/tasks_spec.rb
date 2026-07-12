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
  end
end
