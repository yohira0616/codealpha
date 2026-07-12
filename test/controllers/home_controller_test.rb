require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root returns the SPA html" do
    get root_url

    assert_response :success
    assert_select "div#root"
  end

  test "react router paths fall back to the SPA html" do
    get "/about"

    assert_response :success
    assert_select "div#root"
  end

  test "paths containing dots fall back to the SPA html" do
    get "/users/john.doe"

    assert_response :success
    assert_select "div#root"
  end

  test "wildcard accept requests receive the SPA html" do
    get "/about", headers: { "Accept" => "*/*" }

    assert_response :success
  end

  test "json requests are not caught by the SPA fallback" do
    get "/about", headers: { "Accept" => "application/json" }

    assert_response :not_found
  end

  test "unknown api paths are not caught by the SPA fallback" do
    get "/api/nonexistent"

    assert_response :not_found
  end
end
