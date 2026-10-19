require "test_helper"

module Admin
  class ProductionDashboardControllerTest < ActionDispatch::IntegrationTest
    setup do
      @superadmin = User.create!(
        email_address: "production-dashboard@example.com",
        password: "password123",
        password_confirmation: "password123",
        superadmin: true,
        active_role: :superadmin
      )
      @profile = @superadmin.create_profile!(display_name: "Mark Production", username: "mark_production")
      @assignment = RoleAssignment.create!(profile: @profile, role: :ideatore)
      @brand = Node.create!(
        role_assignment: @assignment,
        title: "PosturaCorretta",
        slug: "production-posturacorretta",
        node_type: :project,
        status: "published"
      )
      @project = Node.create!(
        role_assignment: @assignment,
        parent: @brand,
        title: "Percorso online",
        slug: "production-percorso-online",
        node_type: :project
      )
      @domain = Domain.create!(
        hostname: "production-posturacorretta.test",
        locale: "it",
        node: @brand,
        role_assignment: @assignment,
        primary: true,
        active: true
      )
      @skill = ReusableSkill.create!(
        owner_profile: @profile,
        title: "Contenuti Production",
        slug: "contenuti-production",
        category: "contents",
        status: "testing"
      )
      @activation = ReusableSkillNode.create!(
        reusable_skill: @skill,
        node: @project,
        activated_by_profile: @profile,
        status: "active"
      )
      @product = SkillProduct.create!(
        reusable_skill_node: @activation,
        created_by_profile: @profile,
        title: "Capitolo introduttivo",
        status: "draft",
        visibility: "private",
        format: "markdown"
      )

      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
    end

    test "superadmin opens the Flowpulse dashboard and its system links" do
      get flowpulse_admin_production_url

      assert_response :success
      assert_select "h1", "Dashboard produttiva"
      assert_select "a[href=?]", flowpulse_admin_production_path, text: "Flowpulse"
      assert_select "a[href=?]", flowpulse_admin_brands_path, text: "Generaimpresa"
      assert_select "a[href=?]", rails4b_skills_path, text: "Rails4Business"
      assert_select "a[href=?]", impegno_path(area: "user", view: "agenda"), text: "1impegno"
    end

    test "superadmin adds an unscheduled item to the workbench" do
      assert_difference -> { DataCommitment.count }, 1 do
        post flowpulse_admin_production_inbox_items_url, params: {
          workbench_item: { title: "Preparare il form per i professionisti" }
        }
      end

      item = DataCommitment.order(:created_at).last
      assert_redirected_to flowpulse_admin_production_url(view: "table")
      assert item.workbench_item?
      assert_equal "draft", item.status
      assert_not item.blocks_calendar?
      assert_nil item.starts_at
      assert_equal @domain, item.domain
    end

    test "superadmin classifies a workbench item without scheduling it" do
      item = create_workbench_item

      patch flowpulse_admin_production_inbox_item_url(item), params: {
        workbench_item: {
          title: "Preparare il capitolo introduttivo",
          item_type: "product",
          domain_id: @domain.id,
          subject_node_id: @project.id,
          reusable_skill_id: @skill.id,
          skill_product_id: @product.id,
          product_name: "Capitolo introduttivo",
          responsible_profile_id: @profile.id,
          organization: "production_chain",
          classification_status: "ready"
        }
      }

      item.reload
      assert_redirected_to flowpulse_admin_production_url(view: "table")
      assert_equal @project, item.subject
      assert_equal @product, item.skill_product
      assert_equal @profile, item.responsible_profile
      assert_equal "product", item.workbench_data["item_type"]
      assert_equal "production_chain", item.workbench_data["organization"]
      assert_equal "ready", item.workbench_data["classification_status"]
      assert_nil item.starts_at
    end

    test "project index and node show connect the three operating systems" do
      create_workbench_item.update!(subject: @project, skill_product: @product)

      get flowpulse_admin_production_url(view: "projects")
      assert_response :success
      assert_select "h2", "Progetti e prodotti"
      assert_select "a[href=?]", flowpulse_admin_production_node_path(@project), text: "Percorso online"

      get flowpulse_admin_production_node_url(@project, area: "rails")
      assert_response :success
      assert_select "nav[aria-label='Dettaglio operativo'] a", text: "Generaimpresa"
      assert_select "nav[aria-label='Dettaglio operativo'] a", text: "Rails4Business"
      assert_select "nav[aria-label='Dettaglio operativo'] a", text: "1impegno"
      assert_includes response.body, @skill.title
      assert_includes response.body, @product.title
    end

    private

      def create_workbench_item
        @profile.data_commitments.create!(
          created_by_profile: @profile,
          domain: @domain,
          title: "Voce sul Tavolo",
          kind: "work",
          status: "draft",
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid",
          metadata: {
            "workbench" => {
              "inbox" => true,
              "item_type" => "undecided",
              "organization" => "undecided",
              "classification_status" => "unclassified"
            }
          }
        )
      end
  end
end
