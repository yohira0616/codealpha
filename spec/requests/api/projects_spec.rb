require "rails_helper"

RSpec.describe "Api::Projects" do
  before { sign_in(create(:user)) }

  describe "未ログインの場合" do
    it "401 を返す" do
      delete api_session_path # before のログインを打ち消す

      get api_projects_path

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to be_present
    end
  end

  describe "GET /api/projects" do
    it "集計値つきの一覧を返す" do
      project = create(:project, name: "案件A", daily_rate: 60000)
      create(:task, project:, title: "T1", estimated_days: 2.0, estimated_price: 120000)

      get api_projects_path

      expect(response).to have_http_status(:ok)
      row = response.parsed_body["projects"].sole
      expect(row).to include(
        "name" => "案件A",
        "daily_rate" => 60000,
        "total_estimated_days" => 2.0,
        "total_estimated_price" => 120000
      )
    end
  end

  describe "POST /api/projects" do
    context "有効なパラメータの場合" do
      it "プロジェクトを作成して返す(daily_rate はデフォルト値)" do
        post api_projects_path, params: { project: { name: "新規案件", client_name: "X社" } }, as: :json

        expect(response).to have_http_status(:created)
        json = response.parsed_body["project"]
        expect(json).to include("name" => "新規案件", "daily_rate" => 50000, "tasks" => [])
      end
    end

    context "name が空の場合" do
      it "422 とエラーメッセージを返す" do
        post api_projects_path, params: { project: { name: "" } }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["error"]).to be_present
      end
    end
  end

  describe "GET /api/projects/:id" do
    it "tasks と conversations を含む詳細を返す" do
      project = create(:project, name: "案件B", requirement_text: "要件")
      conversation = create(:conversation, project:, title: "対話1", status: "completed")
      create(:task, project:, conversation:, title: "T1", estimated_days: 1.5)

      get api_project_path(project)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body["project"]
      expect(json["requirement_text"]).to eq("要件")
      expect(json["tasks"].sole["estimated_days"]).to eq(1.5)
      expect(json["conversations"].sole["status"]).to eq("completed")
    end
  end

  describe "PATCH /api/projects/:id" do
    it "更新して詳細を返す" do
      project = create(:project, name: "旧名")

      patch api_project_path(project), params: { project: { name: "新名", daily_rate: 80000 } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["project"]["name"]).to eq("新名")
      expect(project.reload.daily_rate).to eq(80000)
    end
  end
end
