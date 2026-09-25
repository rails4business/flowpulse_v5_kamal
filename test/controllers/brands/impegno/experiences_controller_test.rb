require "test_helper"

module Brands
  module Impegno
    class ExperiencesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email_address: "experience-tree@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
        profile = @user.create_profile!(display_name: "Experience Tree", username: "experience_tree")
        assignment = RoleAssignment.create!(profile: profile, role: :ideatore)
        @professional_node = Node.create!(title: "Experience Professional", slug: "experience-professional", professional: true, role_assignment: assignment)
        @brand = Node.create!(title: "Experience Brand", slug: "experience-brand", parent: @professional_node, professional_owner_node: @professional_node, role_assignment: assignment)
        @calendar = ProfessionalCalendar.create!(context_node: @brand, professional_node: @professional_node, created_by_user: @user, title: "Gruppo", slug: "experience-gruppo", color: "sky")
        @service = Service.create!(node: @brand, created_by_user: @user, title: "Lezione", slug: "lezione")
        @process = BrandProcess.create!(node: @brand, created_by_user: @user, title: "Lezioni", status: "active")
        @domain = Domain.create!(hostname: "experience-tree.test", locale: "it", target_controller: "landing", target_action: "flowpulse", primary: true, active: true)
        post session_url, params: { email_address: @user.email_address, password: "password123" }
      end

      test "builds the minimal experience tree" do
        post impegno_experiences_url, params: { data_experience: { title: "Lezioni del venerdì", description: "Gruppo", brand_process_id: @process.id } }
        experience = DataExperience.order(:created_at).last
        assert_redirected_to impegno_experience_url(experience)
        assert_equal @process, experience.brand_process

        post impegno_experience_sessions_url(experience), params: {
          data_session: { title: "Igiene posturale", starts_at: "2026-09-25T15:00", ends_at: "2026-09-25T16:00", professional_calendar_id: @calendar.id, service_id: @service.id, visibility: "public" }
        }
        data_session = experience.data_sessions.order(:created_at).last
        assert_redirected_to impegno_experience_url(experience)
        assert_equal [@calendar, @service, "public"], [data_session.professional_calendar, data_session.service, data_session.visibility]

        post impegno_session_slots_url(data_session), params: { data_slot: { title: "Punti di tensione" } }
        slot = data_session.data_slots.order(:created_at).last
        assert_redirected_to impegno_experience_url(experience)

        post impegno_slot_commitments_url(slot), params: { data_commitment: { title: "Preparare la scheda" } }
        commitment = slot.data_commitments.order(:created_at).last
        assert_redirected_to impegno_experience_url(experience)
        assert_equal "planned", commitment.status
        assert_equal @user.profile, commitment.profile
        assert_equal 1, commitment.position

        get impegno_experience_url(experience)
        assert_response :success
        assert_select "turbo-frame#experience_workbench"
        assert_select "h1", text: "Lezioni del venerdì"
        assert_select "span", text: "Igiene posturale"
        assert_select "td", text: "Punti di tensione"
        assert_select "td", text: "Igiene posturale"
        assert_select "[data-controller='experience-planned']" do
          assert_select "[data-experience-planned-kind-param='list'] table", count: 1
        end
        assert_select "td", text: "25/09/2026 15:00"
        assert_select "td", text: "16:00"
        assert_select "span", text: "venerdì 25 settembre"

        get impegno_experience_url(experience, vista: "lista")
        assert_response :success
        assert_select "button[aria-selected='true']", text: "Lista"
        assert_select "div[data-experience-planned-kind-param='list']:not(.hidden)", count: 1
        assert_select "div[data-experience-planned-kind-param='day'].hidden", count: 1
        assert_select "div[data-experience-planned-kind-param='day']" do
          assert_select "[data-controller='experience-accordion'] [data-experience-accordion-target='panel'] button", text: "+ Sessione", count: 1
          assert_select "button[data-experience-add-url-param='#{impegno_experience_slots_path(experience)}']", count: 0
          assert_select "button[data-experience-add-url-param='#{impegno_session_slots_path(data_session)}']", text: "+ Slot", count: 1
          assert_select "button[data-experience-add-url-param='#{impegno_session_slots_path(data_session)}'][data-experience-add-starts-at-param='2026-09-25T15:00'][data-experience-add-ends-at-param='2026-09-25T16:00']", count: 1
        end

        patch impegno_experience_path(experience), params: { data_experience: { title: "Lezioni aggiornate", description: "Nuova descrizione" } }
        patch impegno_experience_session_path(experience, data_session), params: { data_session: { title: "Sessione aggiornata", starts_at: "2026-09-25T15:30", ends_at: "2026-09-25T16:30" } }
        patch impegno_session_slot_path(data_session, slot), params: { data_slot: { title: "Slot aggiornato", starts_at: "2026-09-25T15:30", ends_at: "2026-09-25T16:00" } }
        patch impegno_slot_commitment_path(slot, commitment), params: { data_commitment: { title: "Commitment aggiornato", status: "confirmed", starts_at: "2026-09-25T15:30", ends_at: "2026-09-25T16:00" } }
        assert_equal "Lezioni aggiornate", experience.reload.title
        assert_equal "Sessione aggiornata", data_session.reload.title
        assert_equal "Slot aggiornato", slot.reload.title
        assert_equal ["Commitment aggiornato", "confirmed"], [commitment.reload.title, commitment.status]

        get impegno_experience_url(experience)
        assert_response :success
        assert_select "button[data-experience-add-url-param='#{impegno_session_slots_path(data_session)}'][data-experience-add-starts-at-param='2026-09-25T16:00'][data-experience-add-ends-at-param='2026-09-25T16:30']", count: 1
      end

      test "accepts Slot and DataCommitment directly on the experience" do
        experience = DataExperience.create!(created_by_user: @user, title: "Produzione video")

        post impegno_experience_slots_url(experience), params: {
          data_slot: { title: "Montaggio", starts_at: "2026-09-25T09:00", ends_at: "2026-09-25T11:00" }
        }
        direct_slot = experience.data_slots.order(:created_at).last
        assert_nil direct_slot.data_session
        assert_equal experience, direct_slot.data_experience
        assert_equal Time.zone.parse("2026-09-25 09:00"), direct_slot.starts_at

        post impegno_experience_commitments_url(experience), params: { data_commitment: { title: "Definire la scaletta" } }
        direct_commitment = experience.data_commitments.order(:created_at).last
        assert_nil direct_commitment.data_session
        assert_nil direct_commitment.data_slot
        assert_equal 1, direct_commitment.position

        get impegno_experience_url(experience)
        assert_response :success
        assert_select "button", text: "Modifica", count: 1
        assert_select "td", text: "Montaggio"
        assert_select "td", text: "Definire la scaletta"
        assert_select "div[data-experience-planned-kind-param='day'] button[data-experience-add-url-param='#{impegno_slot_commitments_path(direct_slot)}']", text: "+ Commitment", count: 1

        patch impegno_experience_slot_path(experience, direct_slot), params: { data_slot: { title: "Montaggio aggiornato" } }
        patch impegno_experience_commitment_path(experience, direct_commitment), params: { data_commitment: { title: "Scaletta aggiornata", status: "draft" } }
        assert_equal "Montaggio aggiornato", direct_slot.reload.title
        assert_equal ["Scaletta aggiornata", "draft"], [direct_commitment.reload.title, direct_commitment.status]
      end

      test "registers a running activity directly inside the experience" do
        experience = DataExperience.create!(created_by_user: @user, title: "Corso da preparare")

        get impegno_experience_url(experience)
        assert_response :success
        assert_select "button", text: /Registra/
        assert_select "dialog#register-experience-dialog form[action='#{data_commitments_path}']" do
          assert_select "input[name='data_commitment[data_experience_id]'][value='#{experience.id}']"
        end

        assert_difference -> { experience.data_commitments.count }, 1 do
          post data_commitments_url, params: {
            start_now: "1",
            return_to: impegno_experience_path(experience),
            data_commitment: {
              data_experience_id: experience.id,
              domain_id: @domain.id,
              calendar_label: @user.profile.display_name,
              title: "Preparare il programma",
              description: "Ordino Sessioni e Slot.",
              kind: "work"
            }
          }
        end

        commitment = experience.data_commitments.order(:created_at).last
        assert_redirected_to impegno_experience_url(experience)
        assert_equal "in_progress", commitment.status
        assert commitment.actual_started_at.present?
      end

      test "renders the experiences index inside the Impegno workspace" do
        DataExperience.create!(created_by_user: @user, title: "Esperienza nel workspace")

        get impegno_experiences_url(workspace: "1")

        assert_response :success
        assert_select "turbo-frame#impegno_workspace", text: /Esperienza nel workspace/
        assert_select "turbo-frame#impegno_workspace section", count: 1
      end

      test "keeps Experience management restricted to superadmin during the pilot" do
        delete session_url
        regular_user = User.create!(email_address: "experience-regular@example.com", password: "password123", password_confirmation: "password123")
        regular_user.create_profile!(display_name: "Regular Experience", username: "regular_experience")
        post session_url, params: { email_address: regular_user.email_address, password: "password123" }

        assert_no_difference -> { DataExperience.count } do
          post impegno_experiences_url, params: { data_experience: { title: "Esperienza non autorizzata" } }
        end

        assert_response :redirect
      end
    end
  end
end
