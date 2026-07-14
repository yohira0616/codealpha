module Api
  # フロントエンドとの疎通確認用のサンプル API。
  # 新しい API を作るときはこのファイルと app/javascript/lib/api/health.ts の対をひな形にする。
  class HealthController < BaseController
    # 疎通確認用のためログイン不要
    allow_unauthenticated_access

    def show
      render json: {
        status: "ok",
        rails_env: Rails.env,
        time: Time.current
      }
    end
  end
end
