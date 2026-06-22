require "test_helper"

module Admin
  class DomainsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @superadmin = User.create!(
        email_address: "domains-superadmin@example.com",
        password: "password123",
        password_confirmation: "password123",
        superadmin: true,
        active_role: :superadmin
      )

      @traveler = User.create!(
        email_address: "domains-traveler@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      @traveler.create_profile!(display_name: "Traveler User")

      # Create a profile, role assignment (creator) and node to test linking
      @creator_user = User.create!(
        email_address: "domains-creator@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      @profile = @creator_user.create_profile!(display_name: "Creator User")
      @role_assignment = RoleAssignment.create!(
        profile: @profile,
        role: "creator_of_worlds"
      )

      @admin = User.create!(
        email_address: "domains-admin@example.com",
        password: "password123",
        password_confirmation: "password123",
        active_role: :admin
      )
      @admin_profile = @admin.create_profile!(display_name: "Admin User")
      RoleAssignment.create!(
        profile: @admin_profile,
        role: "segreteria_amministrativa",
        parent: @role_assignment
      )
      @node = Node.create!(
        role_assignment: @role_assignment,
        title: "Creator Root Node",
        node_type: "node",
        status: "published"
      )

      @domain = Domain.create!(
        hostname: "example-existing.com",
        locale: "it",
        target_controller: "landing",
        target_action: "posturacorretta",
        active: true
      )
    end

    test "superadmin can view domains list" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      get admin_domains_url
      assert_response :success
    end

    test "superadmin can view new domain form" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      get new_admin_domain_url
      assert_response :success
      assert_select "input[name='domain[logo_full_url]']"
      assert_select "input[name='domain[logo_square_url]']"
      assert_select "input[type='hidden'][name='domain[role_assignment_id]']"
      assert_select "input[type='text'][id='domain_role_assignment_id_input']"
      assert_select "input[type='hidden'][name='domain[node_id]']"
      assert_select "input[type='text'][id='domain_node_id_input']"
    end

    test "superadmin can create domain linked to creator node" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      
      assert_difference "Domain.count", 1 do
        post admin_domains_url, params: {
          domain: {
            hostname: "new-creator-domain.com",
            locale: "it",
            target_controller: "landing",
            target_action: "posturacorretta",
            active: true,
            logo_full_url: "https://cdn.example.com/full.png",
            logo_square_url: "https://cdn.example.com/square.png",
            node_id: @node.id
          }
        }
      end

      domain = Domain.find_by(hostname: "new-creator-domain.com")
      assert_not_nil domain
      assert_equal @node.id, domain.node_id
      assert_equal @role_assignment.id, domain.role_assignment_id
      assert_equal "https://cdn.example.com/full.png", domain.logo_full_url
      assert_equal "https://cdn.example.com/square.png", domain.logo_square_url
      assert_redirected_to admin_domain_path(domain)
    end

    test "superadmin can create domain linked to creator without node" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }

      assert_difference "Domain.count", 1 do
        post admin_domains_url, params: {
          domain: {
            hostname: "new-creator-owner-domain.com",
            locale: "it",
            active: true,
            role_assignment_id: @role_assignment.id,
            node_id: ""
          }
        }
      end

      domain = Domain.find_by(hostname: "new-creator-owner-domain.com")
      assert_not_nil domain
      assert_equal @role_assignment.id, domain.role_assignment_id
      assert_nil domain.node_id
      assert_redirected_to admin_domain_path(domain)
    end

    test "superadmin can update domain and change linked node" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      
      patch admin_domain_url(@domain), params: {
        domain: {
          hostname: "updated-hostname.com",
          node_id: @node.id
        }
      }

      assert_redirected_to admin_domain_path(@domain)
      @domain.reload
      assert_equal "updated-hostname.com", @domain.hostname
      assert_equal @node.id, @domain.node_id
      assert_equal @role_assignment.id, @domain.role_assignment_id
    end

    test "traveler cannot view domains" do
      post session_url, params: { email_address: @traveler.email_address, password: "password123" }
      get admin_domains_url
      assert_redirected_to viaggiatori_url
    end

    test "superadmin with traveler active role cannot view domains" do
      @superadmin.update!(active_role: :traveler)

      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      get admin_domains_url

      assert_redirected_to viaggiatori_url
    end

    test "standard admin cannot access domain actions" do
      post session_url, params: { email_address: @admin.email_address, password: "password123" }
      
      # cannot view list
      get admin_domains_url
      assert_redirected_to admin_dashboard_url

      # cannot view new form
      get new_admin_domain_url
      assert_redirected_to admin_dashboard_url

      # cannot edit
      get edit_admin_domain_url(@domain)
      assert_redirected_to admin_dashboard_url

      # cannot update
      patch admin_domain_url(@domain), params: { domain: { hostname: "illegal-update.com" } }
      assert_redirected_to admin_dashboard_url

      # cannot delete
      assert_no_difference "Domain.count" do
        delete admin_domain_url(@domain)
      end
      assert_redirected_to admin_dashboard_url
    end

    test "superadmin can clear domain creator and node" do
      # Setup domain with creator and node first
      @domain.update!(role_assignment: @role_assignment, node: @node)
      assert_equal @role_assignment.id, @domain.role_assignment_id
      assert_equal @node.id, @domain.node_id

      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }

      # Set role_assignment_id and node_id to blank/nil
      patch admin_domain_url(@domain), params: {
        domain: {
          role_assignment_id: "",
          node_id: ""
        }
      }

      assert_redirected_to admin_domain_path(@domain)
      @domain.reload
      assert_nil @domain.role_assignment_id
      assert_nil @domain.node_id
    end

    test "superadmin clearing creator automatically clears node even if node_id param is omitted or still present" do
      @domain.update!(role_assignment: @role_assignment, node: @node)
      assert_equal @role_assignment.id, @domain.role_assignment_id
      assert_equal @node.id, @domain.node_id

      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }

      # Clear only creator, leaving node_id unchanged
      patch admin_domain_url(@domain), params: {
        domain: {
          role_assignment_id: ""
        }
      }

      assert_redirected_to admin_domain_path(@domain)
      @domain.reload
      assert_nil @domain.role_assignment_id
      assert_nil @domain.node_id
    end
  end
end
