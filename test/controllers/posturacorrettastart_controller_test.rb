require "test_helper"

class PosturacorrettastartControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get posturacorrettastart_url

    assert_redirected_to new_session_url(return_to: posturacorrettastart_path)
  end
end
