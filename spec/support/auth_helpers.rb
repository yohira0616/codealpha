# request spec 用のログインヘルパー。
# セッション API を実際に叩いて Cookie を得る(以降のリクエストに引き継がれる)。
module AuthHelpers
  # password は spec/factories/users.rb のデフォルトに合わせる
  def sign_in(user, password: "password")
    post api_session_path, params: { email_address: user.email_address, password: }, as: :json
  end
end
