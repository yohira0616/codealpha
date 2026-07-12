require "rails_helper"

RSpec.describe "Api::Health" do
  describe "GET /api/health" do
    it "ok ステータスを JSON で返す" do
      get api_health_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("status" => "ok", "rails_env" => "test")
    end
  end
end
