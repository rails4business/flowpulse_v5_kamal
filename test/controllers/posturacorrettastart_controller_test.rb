require "test_helper"

class PosturacorrettastartControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get posturacorrettastart_index_url
    assert_response :success
  end
end
