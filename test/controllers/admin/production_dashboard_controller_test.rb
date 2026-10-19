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

    test "personal planning exposes the three tabs and filters unfinished commitments" do
      unfinished = create_planning_commitment(
        title: "Rivedere il capitolo",
        status: "planned",
        starts_at: Time.zone.local(2026, 10, 20, 9, 0)
      )
      create_planning_commitment(
        title: "Capitolo completato",
        status: "completed",
        starts_at: Time.zone.local(2026, 10, 19, 9, 0)
      )
      create_planning_commitment(
        title: "Attività annullata",
        status: "cancelled",
        starts_at: Time.zone.local(2026, 10, 21, 9, 0)
      )
      workbench_item = create_workbench_item
      other_profile_item = create_planning_commitment(
        profile: create_other_profile,
        title: "Impegno di un'altra persona",
        status: "planned",
        starts_at: Time.zone.local(2026, 10, 20, 11, 0)
      )

      get flowpulse_admin_production_url(view: "planning", planning_tab: "unfinished")

      assert_response :success
      assert_select "nav[aria-label='Pianificazione personale']" do
        assert_select "a[href*='planning_tab=unfinished']", text: /Da completare/
        assert_select "a[href*='planning_tab=agenda']", text: /Agenda/
        assert_select "a[href*='planning_tab=week']", text: "Settimana"
        assert_select "a[aria-current='page']", text: /Da completare/
      end
      assert_includes response.body, unfinished.title
      assert_not_includes response.body, "Capitolo completato"
      assert_not_includes response.body, "Attività annullata"
      assert_not_includes response.body, workbench_item.title
      assert_not_includes response.body, other_profile_item.title
    end

    test "agenda groups the current profile commitments by day" do
      morning = create_planning_commitment(
        title: "Preparare il materiale",
        status: "planned",
        starts_at: Time.zone.local(2026, 10, 20, 9, 0)
      )
      afternoon = create_planning_commitment(
        title: "Presentazione del percorso",
        kind: "event",
        status: "confirmed",
        starts_at: Time.zone.local(2026, 10, 23, 17, 0),
        ends_at: Time.zone.local(2026, 10, 23, 18, 0)
      )
      create_planning_commitment(
        profile: create_other_profile,
        title: "Agenda privata di un'altra persona",
        status: "planned",
        starts_at: Time.zone.local(2026, 10, 20, 10, 0)
      )

      get flowpulse_admin_production_url(
        view: "planning",
        planning_tab: "agenda",
        date: "2026-10-19"
      )

      assert_response :success
      assert_select "nav[aria-label='Pianificazione personale'] a[aria-current='page']", text: /Agenda/
      assert_select "section[data-planning-day='2026-10-20']", text: /#{Regexp.escape(morning.title)}/ do
        assert_select "time[datetime='2026-10-20T09:00:00+02:00']"
      end
      assert_select "section[data-planning-day='2026-10-23']", text: /#{Regexp.escape(afternoon.title)}/ do
        assert_select "time[datetime='2026-10-23T17:00:00+02:00']"
      end
      assert_not_includes response.body, "Agenda privata di un'altra persona"
    end

    test "week planning uses the monday to sunday range around the selected date" do
      monday = create_planning_commitment(
        title: "Revisione del lunedì",
        status: "planned",
        starts_at: Time.zone.local(2026, 10, 19, 9, 0)
      )
      sunday = create_planning_commitment(
        title: "Evento della domenica",
        kind: "event",
        status: "confirmed",
        starts_at: Time.zone.local(2026, 10, 25, 17, 0),
        ends_at: Time.zone.local(2026, 10, 25, 18, 0)
      )
      outside_week = create_planning_commitment(
        title: "Attività della settimana successiva",
        status: "planned",
        starts_at: Time.zone.local(2026, 10, 26, 9, 0)
      )
      other_profile_item = create_planning_commitment(
        profile: create_other_profile,
        title: "Settimana di un'altra persona",
        status: "planned",
        starts_at: Time.zone.local(2026, 10, 21, 10, 0)
      )

      get flowpulse_admin_production_url(
        view: "planning",
        planning_tab: "week",
        date: "2026-10-21"
      )

      assert_response :success
      assert_select "nav[aria-label='Pianificazione personale'] a[aria-current='page']", text: "Settimana"
      assert_select "[data-week-start='2026-10-19'][data-week-end='2026-10-25']", count: 1
      assert_includes response.body, monday.title
      assert_includes response.body, sunday.title
      assert_not_includes response.body, outside_week.title
      assert_not_includes response.body, other_profile_item.title
    end

    private

      def create_planning_commitment(profile: @profile, title:, status:, starts_at:, ends_at: nil, kind: "work")
        profile.data_commitments.create!(
          created_by_profile: profile,
          domain: @domain,
          assignee_profile: profile,
          title: title,
          kind: kind,
          status: status,
          starts_at: starts_at,
          ends_at: ends_at,
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid"
        )
      end

      def create_other_profile
        @other_profile ||= begin
          user = User.create!(
            email_address: "other-production-dashboard@example.com",
            password: "password123",
            password_confirmation: "password123"
          )
          user.create_profile!(display_name: "Other Production", username: "other_production")
        end
      end

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
