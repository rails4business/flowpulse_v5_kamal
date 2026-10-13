require "test_helper"

class BrandAccessesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "brand-accesses-controller@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :traveler
    )
    @user.create_profile!(display_name: "Traveler")
    creator = User.create!(
      email_address: "brand-accesses-controller-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    creator.create_profile!(display_name: "Creator")
    @assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Domain Node", role_assignment: @assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "access-controller.example", node: @node, role_assignment: @assignment, locale: "it", site_title: "Access Brand")
  end

  test "traveler cannot activate brand access without an invitation" do
    sign_in(@user)

    assert_no_difference -> { BrandAccess.count } do
      post brand_accesses_url, params: { domain_id: @domain.id }
    end
    assert_redirected_to new_brand_access_request_url
  end

  test "traveler can remove an existing brand access" do
    access = BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    sign_in(@user)

    delete brand_access_url(access)

    assert_redirected_to viaggiatori_url
    assert_equal "Hai rimosso l'accesso a Domain Node.", flash[:notice]
    assert_equal "cancelled", access.reload.status
  end

  test "another hostname for the same brand does not duplicate the brand access" do
    english_domain = Domain.create!(
      hostname: "access-controller-en.example",
      node: @node,
      role_assignment: @assignment,
      locale: "en",
      site_title: "Access Brand"
    )
    BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    sign_in(@user)

    assert_no_difference -> { BrandAccess.count } do
      post brand_accesses_url, params: { domain_id: english_domain.id }
    end

    brand_access = @user.profile.brand_accesses.find_by!(brand_node: @node)
    assert_equal @domain, brand_access.source_domain
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
