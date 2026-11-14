require "test_helper"

class LineOfferCatalogTest < ActiveSupport::TestCase
  setup do
    user = User.create!(
      email_address: "line-catalog@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    profile = user.create_profile!(display_name: "Line Catalog", username: "markpostura")
    RoleAssignment.create!(profile:, role: :ideatore)
    NodeCatalog.from_config("test").import!
    root = Node.find_by!(slug: "posturacorretta")
    Domain.create!(
      hostname: "posturacorretta.org",
      node: root,
      role_assignment: root.role_assignment,
      active: true,
      primary: true
    )
  end

  test "imports lines and cumulative offers idempotently" do
    catalog = LineOfferCatalog.from_config("test")

    first = catalog.import!
    second = catalog.import!

    line = MetroLine.find_by!(slug: "postura-recupero")
    initial = Offer.find_by!(slug: "prima-settimana-posturacorretta")
    hygiene = Offer.find_by!(slug: "igiene-posturale")
    complete = Offer.find_by!(slug: "area-massaggio-recupero")

    assert_equal 1, first.lines
    assert_equal 3, first.offers
    assert_equal first, second
    assert_equal "posturacorretta.org", line.domain.hostname
    assert_equal "corso-introduzione-al-percorso-integrato", line.start_node.slug
    assert_equal "altre-metodiche-posturali-sintesi-percorso", line.end_node.slug
    assert_equal [
      "corso-introduzione-al-percorso-integrato",
      "introduzione-al-percorso-integrato",
      "corso-la-prima-settimana-con-posturacorretta",
      "la-prima-settimana-con-posturacorretta",
      "postura-e-fisiologia",
      "introduzione-postura-e-fisiologia",
      "area-massaggio-terapie-manuali-tecniche-corporee",
      "igiene-posturale"
    ], line.ordered_nodes.first(8).map(&:slug)
    assert_equal "altre-metodiche-posturali-sintesi-percorso", line.ordered_nodes.last.slug
    assert_not_includes line.nodes, Node.find_by!(slug: "valutazione-mobilita-articolare")
    assert_equal %w[corso-introduzione-al-percorso-integrato corso-la-prima-settimana-con-posturacorretta introduzione-al-percorso-integrato la-prima-settimana-con-posturacorretta], initial.nodes.order(:id).pluck(:slug).sort
    assert_equal [initial], hygiene.included_offers.to_a
    assert_equal [initial, hygiene], complete.included_offers.order(:id).to_a
    assert_equal "credit", hygiene.previous_purchase_mode
    assert_includes hygiene.nodes, Node.find_by!(slug: "igiene-posturale")
    assert_not_includes hygiene.nodes, Node.find_by!(slug: "principi-di-fisioterapia")
  end

  test "removes the lines and offers listed in removed_slugs" do
    root = Node.find_by!(slug: "posturacorretta")
    line = MetroLine.create!(slug: "postura-fisiologia", title: "Postura e fisiologia", domain: Domain.find_by!(hostname: "posturacorretta.org"), start_node: root, end_node: root)
    Offer.create!(slug: "offerta-tolta", title: "Offerta tolta", metro_line: line, start_node: root, end_node: root)
    offers = Rails.application.config_for(:offers, env: "test").to_h.deep_stringify_keys.merge("removed_slugs" => ["offerta-tolta"])

    LineOfferCatalog.new(lines_config: Rails.application.config_for(:metro_lines, env: "test"), offers_config: offers).import!

    assert_not MetroLine.exists?(slug: "postura-fisiologia")
    assert_not Offer.exists?(slug: "offerta-tolta")
  end

  test "rejects an included offer that goes beyond the offer route" do
    offers = Rails.application.config_for(:offers, env: "test").to_h.deep_stringify_keys
    offers["offers"]["igiene-posturale"]["included_offer_slugs"] = ["area-massaggio-recupero"]
    offers["offers"]["area-massaggio-recupero"]["included_offer_slugs"] = []
    catalog = LineOfferCatalog.new(lines_config: Rails.application.config_for(:metro_lines, env: "test"), offers_config: offers)

    error = assert_raises(ArgumentError) { catalog.import! }
    assert_match "l'offerta inclusa area-massaggio-recupero esce dalla tratta", error.message
    assert_not Offer.exists?
  end

  test "rejects nodes outside the route that declare the offer" do
    Node.find_by!(slug: "principi-di-fisioterapia").update!(offer_slugs: %w[igiene-posturale area-massaggio-recupero])

    error = assert_raises(ArgumentError) { LineOfferCatalog.from_config("test").import! }
    assert_match "Node fuori dalla tratta dichiarano l'offerta: principi-di-fisioterapia", error.message
  end
end
