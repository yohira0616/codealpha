require "rails_helper"

RSpec.describe "Home(SPA 配信)" do
  describe "GET /" do
    it "SPA の HTML を返す" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<div id="root">')
    end
  end

  describe "SPA フォールバック(catch-all ルート)" do
    context "React Router 管理下のパスへ直接アクセスした場合" do
      it "SPA の HTML を返す" do
        get "/projects/1"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<div id="root">')
      end
    end

    context "ドットを含むパスの場合" do
      it "フォーマット扱いせず SPA の HTML を返す" do
        get "/users/john.doe"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<div id="root">')
      end
    end

    context "Accept: */* のリクエスト(curl・監視ツール等)の場合" do
      it "SPA の HTML を返す" do
        get "/projects/1", headers: { "Accept" => "*/*" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "JSON を明示するリクエストの場合" do
      it "フォールバックせず 404 を返す" do
        get "/projects/1", headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "存在しない API パスの場合" do
      it "フォールバックせず 404 を返す" do
        get "/api/nonexistent"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
