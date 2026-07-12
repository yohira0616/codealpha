require "test_helper"

module Api
  class HealthControllerTest < ActionDispatch::IntegrationTest
    test "returns ok status as json" do
      get api_health_url

      assert_response :success
      body = response.parsed_body
      assert_equal "ok", body["status"]
      assert_equal "test", body["rails_env"]
    end
  end
end
