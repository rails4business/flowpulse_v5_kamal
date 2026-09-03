require "test_helper"

class DataEventCommitmentTest < ActiveSupport::TestCase
  test "commitment records requested and assigned event separately" do
    user = User.create!(email_address: "event-commitment@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!(display_name: "Partecipante")
    domain = Domain.create!(hostname: "event-commitment.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
    root = DataEvent.create!(
      title: "PosturaCorretta in un mese", classification: "course", node_kind: "root",
      domain: domain, created_by_profile: profile, responsible_profile: profile
    )
    day = DataEvent.create!(
      title: "Martedì 8 settembre", classification: "course", node_kind: "day", parent: root,
      domain: domain, created_by_profile: profile, starts_at: Time.zone.parse("2026-09-08 15:00")
    )
    session = DataEvent.create!(
      title: "Lezione", classification: "course", node_kind: "session", parent: day,
      domain: domain, created_by_profile: profile,
      starts_at: Time.zone.parse("2026-09-08 15:00"), ends_at: Time.zone.parse("2026-09-08 16:00")
    )

    commitment = Brands::Impegno::Commitment.create!(
      profile: profile, created_by_profile: profile, domain: domain,
      requested_data_event: root, data_event: session,
      title: "Partecipazione alla lezione", kind: "academy", status: "confirmed",
      starts_at: session.starts_at, ends_at: session.ends_at,
      participation_role: "participant", pricing_type: "none", contribution_type: "unpaid"
    )

    assert_equal root, commitment.requested_data_event
    assert_equal session, commitment.data_event
    assert_equal "participant", commitment.participation_role
    assert_includes session.data_commitments, commitment
  end

  test "commitment can identify a participant without an account through a contact" do
    user = User.create!(email_address: "caregiver@example.com", password: "password123", password_confirmation: "password123")
    manager = user.create_profile!(display_name: "Familiare")
    domain = Domain.create!(hostname: "represented-participant.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
    contact = Brands::Impegno::Contact.create!(profile: manager, name: "Maria Assistita", kind: "person", phone: "+39 333 1234567")

    commitment = Brands::Impegno::Commitment.create!(
      profile: manager,
      created_by_profile: manager,
      participant_contact: contact,
      domain: domain,
      title: "Partecipazione di Maria",
      kind: "academy",
      status: "requested",
      starts_at: 1.day.from_now,
      blocks_calendar: false,
      pricing_type: "none",
      contribution_type: "unpaid"
    )

    assert_equal contact, commitment.participant_contact
    assert_equal manager, commitment.created_by_profile
    assert_includes contact.participant_data_commitments, commitment
  end

  test "organization contacts cannot be commitment participants" do
    user = User.create!(email_address: "organization-owner@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!(display_name: "Owner")
    domain = Domain.create!(hostname: "organization-participant.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
    organization = Brands::Impegno::Contact.create!(profile: profile, name: "Associazione", kind: "organization")
    commitment = Brands::Impegno::Commitment.new(
      profile: profile, created_by_profile: profile, participant_contact: organization, domain: domain,
      title: "Iscrizione", kind: "academy", status: "requested", starts_at: 1.day.from_now,
      blocks_calendar: false, pricing_type: "none", contribution_type: "unpaid"
    )

    assert_not commitment.valid?
    assert_includes commitment.errors[:participant_contact], "deve essere una persona"
  end
end
