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

  test "traveler can activate and remove brand access" do
    sign_in(@user)

    assert_difference -> { BrandAccess.count }, 1 do
      assert_difference -> { DomainAccess.count }, 1 do
        post brand_accesses_url, params: { domain_id: @domain.id }
      end
    end

    access = @user.profile.brand_accesses.find_by!(brand_node: @node)
    assert_equal @domain, access.source_domain
    assert_equal "active", access.status
    assert @user.profile.domain_accesses.active.exists?(domain: @domain, brand_access: access)
    assert_redirected_to viaggiatori_url
    assert_equal "Ora hai accesso a Access Brand.", flash[:notice]

    delete brand_access_url(access)

    assert_redirected_to viaggiatori_url
    assert_equal "Hai rimosso l'accesso a Domain Node.", flash[:notice]
    assert_equal "cancelled", access.reload.status
    assert @user.profile.domain_accesses.where(brand_access: access, status: "cancelled").exists?
  end

  test "another language adds a domain access without duplicating the brand access" do
    english_domain = Domain.create!(
      hostname: "access-controller-en.example",
      node: @node,
      role_assignment: @assignment,
      locale: "en",
      site_title: "Access Brand"
    )
    sign_in(@user)

    post brand_accesses_url, params: { domain_id: @domain.id }

    assert_no_difference -> { BrandAccess.count } do
      assert_difference -> { DomainAccess.count }, 1 do
        post brand_accesses_url, params: { domain_id: english_domain.id }
      end
    end

    brand_access = @user.profile.brand_accesses.find_by!(brand_node: @node)
    assert_equal ["en", "it"], brand_access.domain_accesses.joins(:domain).order("domains.locale").pluck("domains.locale")
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
