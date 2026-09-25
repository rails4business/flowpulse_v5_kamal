require "test_helper"

module Brands
  module Impegno
    class ProfessionalWorkspaceControllerTest < ActionDispatch::IntegrationTest
      test "shows assigned roles calendars and active services" do
        user = User.create!(email_address: "professional-workspace@example.com", password: "password123", password_confirmation: "password123")
        profile = user.create_profile!(display_name: "Professional Workspace", username: "professional_workspace")
        creator = RoleAssignment.create!(profile: profile, role: :ideatore)
        professional_node = Node.create!(title: "Professional Workspace", slug: "professional-workspace", node_type: :professional, role_assignment: creator)
        profile.update!(primary_node: professional_node)
        context_node = Node.create!(title: "Postura Workspace", slug: "postura-workspace", role_assignment: creator, operator_roles: %w[professional])
        RoleAssignment.create!(profile: profile, role: :operator, role_operator: "professional", context: context_node, parent: creator)
        calendar = ProfessionalCalendar.create!(professional_node: professional_node, context_node: context_node, created_by_user: user, title: "Appuntamenti", slug: "professional-workspace-appuntamenti", color: "emerald")
        active_service = Service.create!(node: context_node, created_by_user: user, title: "Lezione individuale", slug: "lezione-individuale", active: true)
        Service.create!(node: context_node, created_by_user: user, title: "Servizio sospeso", slug: "servizio-sospeso", active: false)
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_professional_url(workspace: "1")

        assert_response :success
        assert_select "turbo-frame#impegno_workspace", count: 1
        assert_select "h1", text: profile.display_name
        assert_select "#professional-roles-title", text: "Ruoli assegnati"
        assert_select "article", text: /Professional/
        assert_select "#professional-calendars-title", text: "Calendari"
        assert_select "article", text: /#{calendar.title}/
        assert_select "#professional-services-title", text: "Servizi attivi"
        assert_select "article", text: /#{active_service.title}/
        assert_select "article", text: /Servizio sospeso/, count: 0
        assert_select "a[href='#{genera_impresa_path}']", text: /GeneraImpresa/
      end

      test "rejects a user without professional or operator access" do
        user = User.create!(email_address: "no-professional-workspace@example.com", password: "password123", password_confirmation: "password123")
        user.create_profile!(display_name: "No Professional Workspace", username: "no_professional_workspace")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_professional_url

        assert_redirected_to impegno_path
      end
    end
  end
end
