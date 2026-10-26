require "test_helper"

class PublicBrandRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "mark-waitlist-owner@example.com", password: "password123")
    @profile = owner.create_profile!(display_name: "Mark Postura")
    assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
    @node = Node.create!(title: "MarkPostura", slug: "markpostura", role_assignment: assignment, status: "published")
    @domain = Domain.create!(hostname: "markpostura.it", node: @node, role_assignment: assignment, primary: true, active: true)
  end

  test "the public form contains the shared anti-spam fields" do
    get "/markpostura"

    assert_response :success
    assert_select "input[name='submission_check[website]']", count: 1
    assert_select "input[name='submission_check[token]'][value]:not([value=''])", count: 1
  end

  test "anonymous visitor joins a brand waiting list without a commitment" do
    assert_difference [-> { BrandRequest.count }, -> { Brands::Impegno::Contact.count }], 1 do
      assert_no_difference -> { DataCommitment.count } do
        post public_brand_requests_url, params: {
          brand_request: {
            brand_slug: "markpostura",
            kind: "waitlist",
            title: "Lista d’attesa · Presentazione MarkPostura",
            name: "Mario Rossi",
            email: "mario@example.com",
            message: "Vorrei capire da dove iniziare.",
            privacy_consent: "1",
            return_to: "/markpostura#lista-attesa"
          }
        }
      end
    end

    brand_request = BrandRequest.order(:created_at).last
    assert_equal "waitlist", brand_request.kind
    assert_equal "waiting", brand_request.status
    assert_equal @node, brand_request.brand_node
    assert_equal "mario@example.com", brand_request.participant_contact.email
    assert_redirected_to "/markpostura#lista-attesa"
  end

  test "same active waiting-list request is not duplicated" do
    params = {
      brand_request: {
        brand_slug: "markpostura", kind: "waitlist", name: "Mario",
        email: "mario@example.com", privacy_consent: "1", return_to: "/markpostura#lista-attesa"
      }
    }
    post public_brand_requests_url, params: params
    assert_no_difference -> { BrandRequest.count } do
      post public_brand_requests_url, params: params
    end
  end
end
