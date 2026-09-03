require "test_helper"

class DataEvents::YamlEventImporterTest < ActiveSupport::TestCase
  test "imports editorial events and programs without duplicating them" do
    user = User.create!(email_address: "yaml-events@example.com", password: "password123", password_confirmation: "password123")
    creator = user.create_profile!(display_name: "Mark YAML", username: "mark_yaml")
    domain = Domain.create!(hostname: "yaml-events.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
    source = Rails.root.join("config/data/posturacorretta/eventi/eventi.yml")
    importer = DataEvents::YamlEventImporter.new(domain_key: "posturacorretta", domain: domain, creator: creator, source_path: source)

    first = importer.call
    second = importer.call

    assert_equal 10, first.fetch(:events).size
    assert_equal first.fetch(:events).map(&:id), second.fetch(:events).map(&:id)
    assert_equal 10, DataEvent.where(domain: domain, node_kind: "root").count

    seminar = DataEvent.where(domain: domain).find_by("metadata @> ?", { "yaml_event_id" => 4 }.to_json)
    assert_equal "completed", seminar.status
    assert_equal "Seminario sulle Catene Muscolari GDS", seminar.title
    assert_equal 1, seminar.children.count
    assert_equal 5, seminar.children.first.children.count
    assert_equal "Registrazione partecipanti ed introduzione alle 5 famiglie muscolari", seminar.children.first.children.first.title
    assert_equal "14:30", seminar.children.first.children.first.starts_at.strftime("%H:%M")
    assert_equal "15:00", seminar.children.first.children.first.ends_at.strftime("%H:%M")
    assert seminar.metadata.fetch("image").present?
    assert_equal ["prevenzione", "fisiologia"], seminar.metadata.fetch("ambiti")
  end
end
