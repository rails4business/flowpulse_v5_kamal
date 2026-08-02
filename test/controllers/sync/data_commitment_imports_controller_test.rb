require "test_helper"

class Sync::DataCommitmentImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "sync@example.test", password: "password123", password_confirmation: "password123")
    @profile = @user.create_profile!(display_name: "Sync", username: "sync_user")
    @payload = {
      schema: "data_commitments/v1",
      exported_at: Time.current.iso8601,
      target_profile_username: @profile.username,
      commitments: [{ sync_key: SecureRandom.uuid, profile_username: @profile.username }]
    }
    @previous_token = ENV["DATA_COMMITMENT_SYNC_TOKEN"]
    ENV["DATA_COMMITMENT_SYNC_TOKEN"] = "test-sync-token"
  end

  teardown do
    ENV["DATA_COMMITMENT_SYNC_TOKEN"] = @previous_token
  end

  test "creates a pending request for the intended profile" do
    assert_difference "DataCommitmentImport.count", 1 do
      post sync_data_commitment_imports_path,
           params: JSON.generate(@payload),
           headers: { "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer test-sync-token" }
    end

    assert_response :created
    import = DataCommitmentImport.last
    assert_equal @profile, import.target_profile
    assert_equal "pending", import.status
    assert_equal "deploy_queue", import.source_type
  end

  test "refuses a request without the shared token" do
    post sync_data_commitment_imports_path, params: JSON.generate(@payload), headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :unauthorized
  end
end
