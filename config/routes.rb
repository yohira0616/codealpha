Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # REST API(JSON)。コントローラは app/controllers/api/ 配下に置き、Api::BaseController を継承する。
  namespace :api do
    get "health", to: "health#show"

    resources :projects, only: [ :index, :show, :create, :update ] do
      resources :conversations, only: [ :create ]
    end
    resources :conversations, only: [ :show ] do
      resources :messages, only: [ :create ]
    end
    resources :tasks, only: [ :update ]
  end

  # React Router 用フォールバック
  # Rails のルーティングに存在せず React Router 側で管理されているパスへ直接アクセス
  # (URL 直打ち・リロード)された場合に SPA の HTML を返し、ルーティングを React Router に委譲する。
  # format: false は /users/john.doe のようなドット入りパスの末尾をフォーマット扱いさせないため。
  get "*path", to: "home#index", format: false, constraints: ->(req) {
    next false if req.xhr? || req.path.start_with?("/api/", "/rails/")

    # ブラウザ(text/html)に加え、Accept 未指定や */* のみ(curl・監視ツール等)にも SPA を返す。
    # JSON など非 HTML を明示するリクエストは除外し 404 にする。
    accepts = req.accepts
    accepts.empty? || accepts.any? { |type| type.html? || type.to_s == "*/*" }
  }

  # Defines the root path route ("/")
  root "home#index"
end
