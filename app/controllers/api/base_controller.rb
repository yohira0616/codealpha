module Api
  class BaseController < ApplicationController
    # API はブラウザのフォーム以外からもアクセスされるため CSRF 検証をスキップする
    skip_before_action :verify_authenticity_token

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
