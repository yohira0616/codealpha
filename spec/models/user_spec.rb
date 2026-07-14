require "rails_helper"

RSpec.describe User do
  describe "email_address の正規化" do
    it "前後の空白を除去し小文字化して保存する" do
      user = create(:user, email_address: " Yamada@Example.COM ")

      expect(user.email_address).to eq("yamada@example.com")
    end
  end

  describe ".authenticate_by" do
    it "正しいパスワードならユーザーを返し、誤りなら nil を返す" do
      user = create(:user, password: "secret123")

      expect(User.authenticate_by(email_address: user.email_address, password: "secret123")).to eq(user)
      expect(User.authenticate_by(email_address: user.email_address, password: "wrong")).to be_nil
    end
  end

  describe "sessions" do
    it "ユーザー削除でセッションも消える" do
      user = create(:user)
      user.sessions.create!

      expect { user.destroy! }.to change(Session, :count).by(-1)
    end
  end
end
