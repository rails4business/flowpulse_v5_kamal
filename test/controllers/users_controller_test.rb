require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    creator = User.create!(
      email_address: "users-controller-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    creator.create_profile!(display_name: "Creator")
    @assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Registration Domain", role_assignment: @assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "registration-domain.example", node: @node, role_assignment: @assignment, locale: "it")
  end

  test "registration with a domain waits for email verification before creating accesses" do
    assert_difference -> { User.count }, 1 do
      assert_difference -> { EmailVerification.count }, 1 do
        assert_no_difference -> { BrandAccess.count } do
          post users_url, params: {
            subscription: @domain.signed_id(purpose: :free_subscription),
            user: {
              email_address: "new-domain-traveler@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end
      end
    end

    user = User.find_by!(email_address: "new-domain-traveler@example.com")
    assert_equal "traveler", user.active_role
    assert user.profile.present?
    assert_equal "pending_email_verification", user.registration_status
    assert_not user.email_verified?
    assert_redirected_to email_verification_sent_path(email: user.email_address)
  end

  test "registration page accepts an authenticated site context locally" do
    Domain.create!(
      hostname: "posturacorretta.org",
      node: @node,
      role_assignment: @assignment,
      target_controller: "brands/posturacorretta",
      target_action: "home",
      locale: "it",
      auth_slug: "posturacorretta",
      auth_enabled: true,
      auth_default_path: "/posturacorretta/dashboard",
      site_title: "PosturaCorretta",
      logo_full_url: "https://cdn.example.com/posturacorretta-logo.png"
    )

    host! "localhost"
    get new_user_path(site: "posturacorretta", return_to: "/posturacorretta/dashboard")

    assert_response :success
    assert_select "title", "Crea account · PosturaCorretta"
    assert_select "input[name='site'][value='posturacorretta']"
    assert_select "input[name='return_to'][value='/posturacorretta/dashboard']"
  end

  test "registration from PosturaCorretta creates access only after email confirmation" do
    posturacorretta = Domain.create!(
      hostname: "posturacorretta.org",
      node: @node,
      role_assignment: @assignment,
      target_controller: "brands/posturacorretta",
      target_action: "home",
      locale: "it",
      auth_slug: "posturacorretta",
      auth_enabled: true,
      auth_default_path: "/posturacorretta/dashboard",
      site_title: "PosturaCorretta"
    )

    host! "localhost"
    get new_user_path(site: "posturacorretta", return_to: "/posturacorretta/dashboard")

    assert_no_difference -> { BrandAccess.count } do
        post users_path, params: {
          site: "posturacorretta",
          return_to: "/posturacorretta/dashboard",
          user: {
            email_address: "new-posturacorretta-member@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
    end

    user = User.find_by!(email_address: "new-posturacorretta-member@example.com")
    assert_equal posturacorretta, user.email_verifications.last.requested_domain
    assert_equal @node, user.email_verifications.last.brand_node
    assert_equal "pending_email_verification", user.registration_status
    assert_redirected_to email_verification_sent_path(email: user.email_address)
  end

  test "registration in a brand context records the requested domain for verification" do
    @domain.update!(
      auth_slug: "posturacorretta",
      auth_enabled: true,
      auth_default_path: "/posturacorretta/dashboard",
      site_title: "PosturaCorretta"
    )

    host! "localhost"
    get new_user_path(site: "posturacorretta")

    assert_no_difference -> { BrandAccess.count } do
        post users_path, params: {
          site: "posturacorretta",
          user: {
            email_address: "new-posturacorretta-traveler@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
    end

    user = User.find_by!(email_address: "new-posturacorretta-traveler@example.com")
    assert_equal @domain, user.email_verifications.last.requested_domain
    assert_equal @node, user.email_verifications.last.brand_node
    assert_redirected_to email_verification_sent_path(email: user.email_address)
  end

  test "invalid brand registration leaves no partial account or access records" do
    @domain.update!(auth_slug: "posturacorretta", auth_enabled: true, auth_default_path: "/posturacorretta/dashboard", site_title: "PosturaCorretta")
    host! "localhost"
    get new_user_path(site: "posturacorretta")

    assert_no_difference [-> { User.count }, -> { BrandAccess.count }] do
      post users_path, params: {
        site: "posturacorretta",
        user: {
          email_address: "invalid-brand-registration@example.com",
          password: "password123",
          password_confirmation: "different-password"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='site'][value='posturacorretta']"
  end

  test "an authenticated user cannot reopen the registration form" do
    user = User.create!(email_address: "already-logged@example.com", password: "password123", password_confirmation: "password123")
    user.create_profile!(display_name: "Already logged")
    post session_url, params: { email_address: user.email_address, password: "password123" }

    get new_user_path
    assert_redirected_to profile_path
  end
end
