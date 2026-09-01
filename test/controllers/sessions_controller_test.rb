require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "sessions-domain-traveler@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @user.create_profile!(display_name: "Traveler")
    creator = User.create!(
      email_address: "sessions-controller-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    creator.create_profile!(display_name: "Creator")
    @assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Login Domain", role_assignment: @assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "login-domain.example", node: @node, role_assignment: @assignment, locale: "it")
  end

  test "login with subscription domain creates free subscription" do
    assert_difference -> { TravelerSubscription.count }, 1 do
      post session_url, params: {
        email_address: @user.email_address,
        password: "password123",
        subscription: @domain.signed_id(purpose: :free_subscription)
      }
    end

    assert @user.profile.traveler_subscriptions.active.exists?(domain: @domain)
    assert_redirected_to root_url
    assert_equal "Ti sei iscritto gratuitamente a login-domain.example.", flash[:notice]
  end

  test "login page uses the PosturaCorretta context from its production host" do
    Domain.create!(
      hostname: "posturacorretta.org",
      target_controller: "brands/posturacorretta",
      target_action: "home",
      locale: "it",
      auth_slug: "posturacorretta",
      auth_default_path: "/posturacorretta/dashboard",
      auth_enabled: true,
      site_title: "PosturaCorretta",
      logo_full_url: "https://cdn.example.com/posturacorretta-logo.png"
    )

    host! "posturacorretta.org"
    get new_session_url(return_to: "/posturacorretta/dashboard")

    assert_response :success
    assert_select "title", "Accedi · PosturaCorretta"
    assert_select "img[alt='PosturaCorretta'][src='https://cdn.example.com/posturacorretta-logo.png']"
    assert_select "header[aria-label]", count: 0
    assert_select "header nav[aria-label='Navigazione principale PosturaCorretta']"
    assert_select "input[name='site']", count: 0
  end

  test "login from PosturaCorretta creates a domain membership without a node" do
    posturacorretta = Domain.create!(
      hostname: "posturacorretta.org",
      target_controller: "brands/posturacorretta",
      target_action: "home",
      locale: "it",
      auth_slug: "posturacorretta",
      auth_enabled: true,
      auth_default_path: "/posturacorretta/dashboard",
      site_title: "PosturaCorretta"
    )

    host! "localhost"
    get new_session_path(site: "posturacorretta", return_to: "/posturacorretta/dashboard")

    assert_difference -> { DomainMembership.count }, 1 do
      post session_path, params: { site: "posturacorretta", email_address: @user.email_address, password: "password123" }
    end

    assert @user.profile.domain_memberships.active.exists?(domain: posturacorretta)
    assert_redirected_to "/posturacorretta/dashboard"
    assert_equal "Benvenuto in PosturaCorretta.", flash[:notice]
  end

  test "login in a brand context creates a traveler subscription when the domain has a node" do
    @domain.update!(
      auth_slug: "posturacorretta",
      auth_enabled: true,
      auth_default_path: "/posturacorretta/dashboard",
      site_title: "PosturaCorretta"
    )

    host! "localhost"
    get new_session_path(site: "posturacorretta")

    assert_difference -> { DomainMembership.count }, 1 do
      assert_difference -> { TravelerSubscription.count }, 1 do
        post session_path, params: {
          site: "posturacorretta",
          email_address: @user.email_address,
          password: "password123"
        }
      end
    end

    assert @user.profile.traveler_subscriptions.active.exists?(node: @node)
    assert @user.profile.domain_memberships.active.exists?(domain: @domain)
    assert_redirected_to "/posturacorretta/dashboard"
  end

  test "login from PosturaCorretta uses its dashboard as the default destination" do
    Domain.create!(
      hostname: "posturacorretta.org",
      target_controller: "brands/posturacorretta",
      target_action: "home",
      locale: "it",
      auth_slug: "posturacorretta",
      auth_enabled: true,
      auth_default_path: "/posturacorretta/dashboard",
      site_title: "PosturaCorretta"
    )

    host! "localhost"
    get new_session_path(site: "posturacorretta")
    post session_path, params: { site: "posturacorretta", email_address: @user.email_address, password: "password123" }

    assert_redirected_to "/posturacorretta/dashboard"
  end

  test "login from PosturaCorretta rejects external and unrelated return paths" do
    Domain.create!(
      hostname: "posturacorretta.org",
      target_controller: "brands/posturacorretta",
      target_action: "home",
      locale: "it",
      auth_slug: "posturacorretta",
      auth_enabled: true,
      auth_default_path: "/posturacorretta/dashboard",
      site_title: "PosturaCorretta"
    )

    host! "localhost"
    get new_session_path(site: "posturacorretta", return_to: "https://evil.example")
    post session_path, params: { site: "posturacorretta", email_address: @user.email_address, password: "password123" }
    assert_redirected_to "/posturacorretta/dashboard"

    delete session_path
    get new_session_path(site: "posturacorretta", return_to: "/impegno")
    post session_path, params: { site: "posturacorretta", email_address: @user.email_address, password: "password123" }
    assert_redirected_to "/posturacorretta/dashboard"
  end

  test "an authenticated user cannot reopen the login form" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get new_session_path
    assert_redirected_to profile_path

    posturacorretta = Domain.create!(
      hostname: "posturacorretta.org",
      target_controller: "brands/posturacorretta",
      target_action: "home",
      locale: "it",
      auth_slug: "posturacorretta",
      auth_enabled: true,
      auth_default_path: "/posturacorretta/dashboard",
      site_title: "PosturaCorretta"
    )
    host! "localhost"
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    get new_session_path(site: posturacorretta.auth_slug)
    assert_redirected_to "/posturacorretta/dashboard"
  end
end
