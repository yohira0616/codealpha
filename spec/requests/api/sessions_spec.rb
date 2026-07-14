require "rails_helper"

RSpec.describe "Api::Sessions" do
  let(:user) { create(:user, email_address: "yamada@example.com") }

  describe "POST /api/session" do
    context "正しい認証情報の場合" do
      it "セッションを作成してユーザーを返す" do
        post api_session_path, params: { email_address: user.email_address, password: "password" }, as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["user"]).to include("id" => user.id, "email_address" => "yamada@example.com")
        expect(user.sessions.count).to eq(1)
      end

      it "メールアドレスは大文字・空白ありでも認証できる(normalizes)" do
        user # let は遅延評価のため先に作成しておく

        post api_session_path, params: { email_address: " YAMADA@example.com ", password: "password" }, as: :json

        expect(response).to have_http_status(:created)
      end
    end

    context "パスワードが誤っている場合" do
      it "401 を返しセッションを作らない" do
        post api_session_path, params: { email_address: user.email_address, password: "wrong" }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to be_present
        expect(user.sessions.count).to eq(0)
      end
    end

    context "パラメータが欠けている場合" do
      it "500 にならず 401 を返す" do
        post api_session_path, params: { email_address: user.email_address }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/session" do
    it "ログイン中は現在のユーザーを返す" do
      sign_in(user)

      get api_session_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["user"]["id"]).to eq(user.id)
    end

    it "未ログインは 401 を返す" do
      get api_session_path

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/session" do
    it "セッションを破棄し、以降の API は 401 になる" do
      sign_in(user)

      delete api_session_path
      expect(response).to have_http_status(:no_content)
      expect(user.sessions.count).to eq(0)

      get api_projects_path
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
