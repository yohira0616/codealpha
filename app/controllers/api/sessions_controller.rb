module Api
  class SessionsController < BaseController
    include Serialization

    allow_unauthenticated_access only: :create
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
      render json: { error: "試行回数が多すぎます。しばらく待ってからやり直してください" }, status: :too_many_requests
    }

    # POST /api/session ログイン
    def create
      # authenticate_by はキー欠落だと ArgumentError になるため、常に両キーを渡す
      credentials = { email_address: params[:email_address].to_s, password: params[:password].to_s }
      if (user = User.authenticate_by(credentials))
        start_new_session_for(user)
        render json: { user: user_json(user) }, status: :created
      else
        render json: { error: "メールアドレスまたはパスワードが正しくありません" }, status: :unauthorized
      end
    end

    # GET /api/session ログイン状態確認(未ログインは require_authentication が 401 を返す)
    def show
      render json: { user: user_json(Current.user) }
    end

    # DELETE /api/session ログアウト
    def destroy
      terminate_session
      head :no_content
    end
  end
end
