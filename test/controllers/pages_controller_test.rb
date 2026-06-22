require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @traveler = User.create!(
      email_address: "traveler-dashboard-subscriptions@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :traveler
    )
    @traveler.create_profile!(display_name: "Traveler")
    creator = User.create!(
      email_address: "traveler-dashboard-subscriptions-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    creator.create_profile!(display_name: "Creator")
    @assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
  end

  test "traveler dashboard filters subscriptions by current domain subtree" do
    root = Node.create!(title: "Flowpulse Root", role_assignment: @assignment, status: "published", visibility: "public")
    posture = Node.create!(title: "Postura Corretta", role_assignment: @assignment, parent: root, status: "published", visibility: "public")
    igiene = Node.create!(title: "Igiene Posturale", role_assignment: @assignment, parent: posture, status: "published", visibility: "public")
    outside = Node.create!(title: "Outside", role_assignment: @assignment, status: "published", visibility: "public")
    flowpulse = Domain.create!(hostname: "flowpulse.example", node: root, role_assignment: @assignment, locale: "it")
    postura = Domain.create!(hostname: "postura.example", node: posture, role_assignment: @assignment, locale: "it")
    igiene_domain = Domain.create!(hostname: "igiene.example", node: igiene, role_assignment: @assignment, locale: "it")
    outside_domain = Domain.create!(hostname: "outside.example", node: outside, role_assignment: @assignment, locale: "it")
    [flowpulse, postura, igiene_domain, outside_domain].each do |domain|
      TravelerSubscription.create!(profile: @traveler.profile, domain: domain)
    end

    host! "postura.example"
    sign_in(@traveler)
    get viaggiatori_path

    assert_response :success
    assert_no_match "flowpulse.example", response.body
    assert_includes response.body, "postura.example"
    assert_includes response.body, "igiene.example"
    assert_no_match "outside.example", response.body
    assert_operator response.body.index("postura.example"), :<, response.body.index("igiene.example")
    assert_select "nav[aria-label='Navigazione dashboard']" do
      assert_select "h3", text: "Domini iscritti"
      assert_select "a[href=?]", node_path(posture), text: /postura\.example/
      assert_select "a[href=?]", node_path(igiene), text: /igiene\.example/
      assert_select "a[href=?]", node_path(root), count: 0
      assert_select "a[href=?]", node_path(outside), count: 0
    end
  end

  private

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
