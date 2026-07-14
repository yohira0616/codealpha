module Api
  class BaseController < ApplicationController
    # Cookie セッション認証のため CSRF 検証は有効のまま。
    # フロント(lib/api.ts)は常に X-CSRF-Token を送信している。
    include Authentication

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "リソースが見つかりません" }, status: :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render json: { error: e.record.errors.full_messages }, status: :unprocessable_content
    end

    rescue_from ActionController::ParameterMissing do |e|
      render json: { error: e.message }, status: :bad_request
    end
  end
end
