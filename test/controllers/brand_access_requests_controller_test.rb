require "test_helper"

class BrandAccessRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "access-request-owner@example.com", password: "password123")
    @profile = owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
    @node = Node.create!(title: "PosturaCorretta", role_assignment: assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "posturacorretta.org", node: @node, role_assignment: assignment, locale: "it", auth_slug: "posturacorretta", auth_enabled: true, site_title: "PosturaCorretta")
  end

  test "shows the invitation request for the selected brand" do
    host! "localhost"
    get new_brand_access_request_path(site: "posturacorretta")
    assert_response :success
    assert_select "h1", "Richiedi un invito"
    assert_select "form[action='#{brand_access_request_path}']"
  end

  test "creates an unscheduled brand request and contact" do
    host! "localhost"
    assert_difference [-> { Brands::Impegno::Contact.count }, -> { Brands::Impegno::Commitment.count }], 1 do
      post brand_access_request_path, params: {
        site: "posturacorretta",
        access_request: { name: "Mario Rossi", email: "mario@example.com", phone: "333123456", message: "Vorrei partecipare.", privacy_consent: "1" }
      }
    end
    commitment = Brands::Impegno::Commitment.order(:created_at).last
    assert_equal "requested", commitment.status
    assert_equal "access_invitation", commitment.metadata["request_kind"]
    assert_not commitment.blocks_calendar?
    assert_nil commitment.starts_at
    assert_equal @node, commitment.subject
  end

  test "does not duplicate an open request for the same email and brand" do
    request_params = { site: "posturacorretta", access_request: { name: "Mario", email: "mario@example.com", privacy_consent: "1" } }
    post brand_access_request_path, params: request_params
    assert_no_difference -> { Brands::Impegno::Commitment.count } do
      post brand_access_request_path, params: request_params
    end
  end
end
