require "test_helper"

class DataCommitmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "commitment-superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    @profile = @user.create_profile!(display_name: "Mark Postura", username: "markpostura")
    @domain = Domain.create!(
      hostname: "posturacorretta.org",
      locale: "it",
      target_controller: "landing",
      target_action: "posturacorretta",
      primary: true,
      active: true
    )
    host! "posturacorretta.org"
    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "uses the namespaced Impegno model while preserving the legacy alias" do
    assert_equal Brands::Impegno::Commitment, DataCommitment
    assert_equal "data_commitments", Brands::Impegno::Commitment.table_name
    assert_equal Brands::Impegno::Commitment, Profile.reflect_on_association(:data_commitments).klass
  end

  test "superadmin records a calendar commitment for a GeneraImpresa task" do
    assert_difference -> { DataCommitment.count }, 1 do
      post data_commitments_url, params: {
        project_slug: "percorsi-personalizzati-linee-guida",
        step_key: "raccogliere-bisogni-obiettivi",
        task_key: "definire-profili-tipo",
        data_commitment: {
          title: "Definire i profili tipo",
          description: "Raccolti e ordinati i bisogni principali.",
          starts_at: "2026-07-29T09:00",
          ends_at: "2026-07-29T11:30",
          pricing_type: "hourly",
          hourly_rate: "40",
          contribution_type: "time_investment"
        }
      }
    end

    commitment = DataCommitment.last
    assert_redirected_to posturacorretta_progetto_url(
      "percorsi-personalizzati-linee-guida",
      tab: "phases",
      phase: "implementation",
      anchor: "task-raccogliere-bisogni-obiettivi-definire-profili-tipo"
    )
    assert_equal @profile, commitment.profile
    assert_equal @profile, commitment.created_by_profile
    assert_equal @domain, commitment.domain
    assert_equal 150, commitment.duration_minutes
    assert_equal BigDecimal("100"), commitment.total_price
    assert_equal "implementation", commitment.genera_impresa["phase_key"]
    assert_equal "definire-profili-tipo", commitment.genera_impresa["task_key"]

    get posturacorretta_progetto_url(
      "percorsi-personalizzati-linee-guida",
      tab: "phases",
      phase: "implementation"
    )
    assert_response :success
    assert_includes response.body, "Raccolti e ordinati i bisogni principali."
    assert_includes response.body, "@markpostura"
  end

  test "owner starts completes and edits a commitment" do
    commitment = DataCommitment.create!(
      profile: @profile,
      created_by_profile: @profile,
      domain: @domain,
      title: "Preparare le domande",
      kind: "personal",
      status: "planned",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      pricing_type: "none",
      contribution_type: "unpaid"
    )

    patch start_data_commitment_url(commitment)
    assert_redirected_to data_commitments_url(tab: "upcoming", anchor: "commitment-#{commitment.id}")
    assert commitment.reload.tracking?

    patch complete_data_commitment_url(commitment)
    commitment.reload
    assert_equal "completed", commitment.status
    assert commitment.actual_ended_at.present?

    patch data_commitment_url(commitment), params: {
      data_commitment: {
        title: "Preparare le domande aggiornate",
        description: "Revisione completata",
        domain_id: @domain.id,
        kind: "content",
        starts_at: commitment.starts_at.iso8601,
        ends_at: commitment.ends_at.iso8601,
        context_label: "Percorso personalizzato"
      }
    }
    assert_equal "Preparare le domande aggiornate", commitment.reload.title
    assert_equal "Percorso personalizzato", commitment.metadata["context_label"]
  end

  test "superadmin starts and completes a timer from a GeneraImpresa task" do
    assert_difference -> { DataCommitment.count }, 1 do
      post data_commitments_url, params: {
        project_slug: "percorsi-personalizzati-linee-guida",
        step_key: "raccogliere-bisogni-obiettivi",
        task_key: "definire-profili-tipo",
        start_now: true,
        data_commitment: { description: "Analizzare e ordinare i bisogni raccolti." }
      }
    end

    commitment = DataCommitment.last
    assert commitment.tracking?
    assert_equal "work", commitment.kind
    assert_equal "Analizzare e ordinare i bisogni raccolti.", commitment.description
    assert_equal "definire-profili-tipo", commitment.genera_impresa["task_key"]

    patch complete_data_commitment_url(commitment)
    assert_equal "completed", commitment.reload.status
    assert commitment.actual_ended_at.present?
    assert_redirected_to posturacorretta_progetto_url(
      "percorsi-personalizzati-linee-guida",
      tab: "phases",
      phase: "implementation",
      anchor: "task-raccogliere-bisogni-obiettivi-definire-profili-tipo"
    )
  end

  test "superadmin completes and reopens a GeneraImpresa step without activities" do
    assert_difference -> { DataCommitment.count }, 1 do
      post complete_step_data_commitments_url, params: {
        project_slug: "percorsi-personalizzati-linee-guida",
        step_key: "raccogliere-bisogni-obiettivi",
        completion_note: "Definizione conclusa sulla base dei materiali già disponibili."
      }
    end

    marker = DataCommitment.last
    assert_equal "step_completion", marker.genera_impresa["record_type"]
    assert_equal "raccogliere-bisogni-obiettivi", marker.genera_impresa["step_key"]
    assert_equal false, marker.blocks_calendar
    assert marker.metadata["missing_data_at_completion"].any?
    assert_redirected_to posturacorretta_progetto_url("percorsi-personalizzati-linee-guida", tab: "phases", phase: "implementation", anchor: "step-raccogliere-bisogni-obiettivi")

    assert_difference -> { DataCommitment.count }, -1 do
      delete data_commitment_url(marker)
    end
  end

  test "superadmin records an activity on a step without assigning a task" do
    assert_difference -> { DataCommitment.count }, 1 do
      post data_commitments_url, params: {
        project_slug: "percorsi-personalizzati-linee-guida",
        step_key: "raccogliere-bisogni-obiettivi",
        data_commitment: {
          title: "Revisione libera dello step",
          description: "Riorganizzati i materiali prima di definire il task corretto.",
          starts_at: "2026-08-01T09:00",
          ends_at: "2026-08-01T10:30",
          pricing_type: "hourly",
          hourly_rate: "40",
          contribution_type: "time_investment"
        }
      }
    end

    commitment = DataCommitment.last
    assert_equal "raccogliere-bisogni-obiettivi", commitment.genera_impresa["step_key"]
    assert_nil commitment.genera_impresa["task_key"]
    assert_equal BigDecimal("60"), commitment.total_price
    assert_redirected_to posturacorretta_progetto_url("percorsi-personalizzati-linee-guida", tab: "phases", phase: "implementation", anchor: "step-raccogliere-bisogni-obiettivi")

    get posturacorretta_progetto_url("percorsi-personalizzati-linee-guida", tab: "phases", phase: "implementation")
    assert_response :success
    assert_includes response.body, "Riorganizzati i materiali prima di definire il task corretto."
    assert_includes response.body, "Non ancora associate a un task"
  end

  test "PosturaCorretta commitments are private and scoped to the current domain" do
    other_domain = Domain.create!(
      hostname: "flowpulse.net",
      locale: "it",
      target_controller: "landing",
      target_action: "flowpulse",
      primary: true,
      active: true
    )
    DataCommitment.create!(profile: @profile, created_by_profile: @profile, domain: @domain, title: "Impegno PosturaCorretta", kind: "personal", status: "planned", starts_at: 1.day.from_now, pricing_type: "none", contribution_type: "unpaid")
    DataCommitment.create!(profile: @profile, created_by_profile: @profile, domain: other_domain, title: "Impegno Flowpulse", kind: "personal", status: "planned", starts_at: 1.day.from_now, pricing_type: "none", contribution_type: "unpaid")

    get impegno_agenda_url(workspace: "1")
    assert_response :success
    assert_includes response.body, "Impegno PosturaCorretta"
    assert_not_includes response.body, "Impegno Flowpulse"

    delete session_url
    get impegno_agenda_url(workspace: "1")
    assert_redirected_to new_session_url
  end

  test "PosturaCorretta exposes its dedicated calendar path" do
    get posturacorretta_impegno_url

    assert_response :success
    assert_select "select[name=brand] option[selected][value=posturacorretta]", text: "PosturaCorretta"
    assert_select "turbo-frame#impegno_workspace[src*='brand_scope=posturacorretta']", count: 1
  end

  test "canonical Impegno Agenda path filters commitments by the selected day" do
    selected_day = Date.new(2026, 8, 2)
    commitment = DataCommitment.create!(profile: @profile, created_by_profile: @profile, domain: @domain, title: "Dato del giorno", kind: "personal", status: "planned", starts_at: selected_day.in_time_zone.change(hour: 9), pricing_type: "none", contribution_type: "unpaid", location_name: "Studio Calvisano", metadata: { "context_label" => "Percorso personale" })
    DataCommitment.create!(profile: @profile, created_by_profile: @profile, domain: @domain, title: "Dato di un altro giorno", kind: "personal", status: "planned", starts_at: selected_day.next_day.in_time_zone.change(hour: 9), pricing_type: "none", contribution_type: "unpaid")

    get impegno_agenda_url(workspace: "1", date: selected_day.iso8601)

    assert_response :success
    assert_select "turbo-frame#impegno_workspace", count: 1
    assert_select "article#commitment-#{commitment.id}", text: /Dato del giorno/
    assert_includes response.body, "Dato del giorno"
    assert_includes response.body, "Percorso personale · Studio Calvisano"
    assert_not_includes response.body, "Dato di un altro giorno"
  end

  test "legacy and direct Agenda page URLs return to the single Impegno shell" do
    get legacy_data_commitments_url
    assert_redirected_to impegno_url(area: "user", view: "agenda")

    get impegno_agenda_url
    assert_redirected_to impegno_url(area: "user", view: "agenda")
  end

  test "same logical calendar cannot contain overlapping commitments" do
    start_time = 2.days.from_now.change(hour: 10, min: 0)
    common = {
      domain_id: @domain.id,
      kind: "appointment",
      calendar_label: "Paziente senza account",
      starts_at: start_time.iso8601,
      ends_at: (start_time + 1.hour).iso8601
    }

    post data_commitments_url, params: { data_commitment: common.merge(title: "Prima visita") }
    first = DataCommitment.last
    assert_equal "Paziente senza account", first.calendar_label
    assert_nil first.assignee_profile

    assert_no_difference -> { DataCommitment.count } do
      post data_commitments_url, params: { data_commitment: common.merge(title: "Appuntamento sovrapposto", starts_at: (start_time + 30.minutes).iso8601, ends_at: (start_time + 90.minutes).iso8601) }
    end
    assert_includes flash[:alert], "stesso intervallo"

    assert_difference -> { DataCommitment.count }, 1 do
      post data_commitments_url, params: { data_commitment: common.merge(title: "Altro paziente", calendar_label: "Secondo paziente") }
    end
  end

  test "same calendar cannot start a second timer" do
    first = DataCommitment.create!(
      profile: @profile,
      created_by_profile: @profile,
      domain: @domain,
      title: "Prima attività",
      kind: "personal",
      status: "planned",
      starts_at: 1.hour.from_now,
      pricing_type: "none",
      contribution_type: "unpaid"
    )
    second = DataCommitment.create!(
      profile: @profile,
      created_by_profile: @profile,
      domain: @domain,
      title: "Seconda attività",
      kind: "personal",
      status: "planned",
      starts_at: 2.hours.from_now,
      pricing_type: "none",
      contribution_type: "unpaid"
    )

    patch start_data_commitment_url(first)
    assert first.reload.tracking?

    patch start_data_commitment_url(second)
    assert_redirected_to data_commitments_url(tab: "upcoming", anchor: "commitment-#{second.id}")
    assert_equal "planned", second.reload.status
    assert_includes flash[:alert], "già un’attività in corso"
  end

  test "different supervised calendars can track activities at the same time" do
    first = DataCommitment.create!(
      profile: @profile,
      created_by_profile: @profile,
      domain: @domain,
      calendar_key: "person:paziente-a",
      calendar_label: "Paziente A",
      title: "Supervisione A",
      kind: "appointment",
      status: "planned",
      starts_at: 1.hour.from_now,
      pricing_type: "none",
      contribution_type: "unpaid"
    )
    second = DataCommitment.create!(
      profile: @profile,
      created_by_profile: @profile,
      domain: @domain,
      calendar_key: "person:paziente-b",
      calendar_label: "Paziente B",
      title: "Supervisione B",
      kind: "appointment",
      status: "planned",
      starts_at: 1.hour.from_now,
      pricing_type: "none",
      contribution_type: "unpaid"
    )

    patch start_data_commitment_url(first)
    patch start_data_commitment_url(second)

    assert first.reload.tracking?
    assert second.reload.tracking?
  end

  test "owner deletes a commitment with the destroy action" do
    commitment = DataCommitment.create!(profile: @profile, created_by_profile: @profile, domain: @domain, title: "Da eliminare", kind: "personal", status: "planned", starts_at: 1.day.from_now, pricing_type: "none", contribution_type: "unpaid")

    assert_difference -> { DataCommitment.count }, -1 do
      delete data_commitment_url(commitment)
    end
    assert_redirected_to data_commitments_url(tab: "upcoming", anchor: "commitment-#{commitment.id}")
  end
end
