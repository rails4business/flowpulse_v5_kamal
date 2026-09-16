require "test_helper"

class DomainTest < ActiveSupport::TestCase
  test "configures 1impegno as an authenticated primary domain" do
    config = Rails.application.config_for(:domains, env: Rails.env).with_indifferent_access.fetch("1impegno.it")

    assert_equal "brands/impegno/home", config.fetch("target_controller")
    assert_equal "index", config.fetch("target_action")
    assert_equal "impegno", config.fetch("auth_slug")
    assert_equal "/impegno", config.fetch("auth_default_path")
    assert_equal true, config.fetch("auth_enabled")
  end

  test "configures MarkPostura through its editorial Site" do
    config = Rails.application.config_for(:domains, env: Rails.env).with_indifferent_access.fetch("markpostura.it")

    assert_equal "markpostura_it", config.fetch("site_key")
    assert_nil config[:target_controller]
    assert_nil config[:target_action]
  end

  test "imports and exports an editorial site key" do
    Domain.import_from_hash!(
      "editorial.example" => {
        "locale" => "it",
        "site_key" => "markpostura_it"
      }
    )

    domain = Domain.find_by!(hostname: "editorial.example")
    assert_equal "markpostura_it", domain.site_key
    assert_equal "markpostura_it", Domain.export_to_hash.dig("editorial.example", "site_key")
  end

  test "normalizes hostnames" do
    domain = Domain.create!(
      hostname: " POSTURACORRETTA.ORG ",
      target_controller: "landing",
      target_action: "posturacorretta",
      locale: "it"
    )

    assert_equal "posturacorretta.org", domain.hostname
  end

  test "normalizes hostnames with ports" do
    domain = Domain.create!(
      hostname: " POSTURACORRETTA.ORG:443 ",
      target_controller: "landing",
      target_action: "posturacorretta",
      locale: "it"
    )

    assert_equal "posturacorretta.org", domain.hostname
  end

  test "finds active domain by host" do
    primary = Domain.create!(hostname: "posturacorretta.org", target_controller: "landing", target_action: "posturacorretta", locale: "it")
    alias_domain = Domain.create!(hostname: "www.posturacorretta.org", canonical_host: "posturacorretta.org", locale: "it")

    assert_equal primary, Domain.find_for_host("POSTURACORRETTA.ORG")
    assert_equal primary, Domain.find_for_host("www.posturacorretta.org")
  end

  test "finds active domain by www fallback when alias record is missing" do
    primary = Domain.create!(hostname: "posturacorretta.org", target_controller: "landing", target_action: "posturacorretta", locale: "it")

    assert_equal primary, Domain.find_for_host("www.posturacorretta.org")
  end

  test "exports config hash" do
    Domain.create!(
      hostname: "www.posturacorretta.org",
      canonical_host: "posturacorretta.org",
      logo_full_url: "https://cdn.example.com/logo-full.png",
      logo_square_url: "https://cdn.example.com/logo-square.png",
      favicon_url: "https://cdn.example.com/favicon.png",
      social_image_url: "https://cdn.example.com/social.png",
      site_title: "PosturaCorretta",
      site_description: "Descrizione del dominio",
      auth_slug: " PosturaCorretta ",
      auth_default_path: "/posturacorretta/dashboard",
      auth_enabled: true,
      locale: "it"
    )

    assert_equal "posturacorretta.org", Domain.export_to_hash["www.posturacorretta.org"]["canonical_host"]
    assert_equal "https://cdn.example.com/logo-full.png", Domain.export_to_hash["www.posturacorretta.org"]["logo_full_url"]
    assert_equal "https://cdn.example.com/logo-square.png", Domain.export_to_hash["www.posturacorretta.org"]["logo_square_url"]
    assert_equal "https://cdn.example.com/favicon.png", Domain.export_to_hash["www.posturacorretta.org"]["favicon_url"]
    assert_equal "https://cdn.example.com/social.png", Domain.export_to_hash["www.posturacorretta.org"]["social_image_url"]
    assert_equal "PosturaCorretta", Domain.export_to_hash["www.posturacorretta.org"]["site_title"]
    assert_equal "posturacorretta", Domain.export_to_hash["www.posturacorretta.org"]["auth_slug"]
    assert_equal "/posturacorretta/dashboard", Domain.export_to_hash["www.posturacorretta.org"]["auth_default_path"]
    assert_equal true, Domain.export_to_hash["www.posturacorretta.org"]["auth_enabled"]
  end

  test "display hostname removes www prefix" do
    domain = Domain.new(hostname: "www.posturacorretta.org")

    assert_equal "posturacorretta.org", domain.display_hostname
  end

  test "syncs role assignment from node and supports alias domains" do
    user = User.create!(
      email_address: "creator-domain-test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Domain Test Creator")
    ra = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
    root_node = Node.create!(title: "Root Page", slug: "root-page", role_assignment: ra)

    # Domain 1 (non-www) pointing to root_node
    domain1 = Domain.create!(
      hostname: "posturacorretta.org",
      node: root_node,
      locale: "it"
    )

    # Domain 2 (www alias) pointing to root_node
    domain2 = Domain.create!(
      hostname: "www.posturacorretta.org",
      canonical_host: "posturacorretta.org",
      node: root_node,
      locale: "it"
    )

    # Both transitively resolve to the same RoleAssignment
    assert_equal ra, domain1.role_assignment
    assert_equal ra, domain2.role_assignment
    assert_equal ra.id, domain1.role_assignment_id
    assert_equal ra.id, domain2.role_assignment_id

    # RoleAssignment should be able to fetch both domains
    assert_includes ra.domains, domain1
    assert_includes ra.domains, domain2
  end

  test "can assign a creator world without assigning a node" do
    user = User.create!(
      email_address: "creator-domain-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Domain Owner")
    ra = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)

    domain = Domain.create!(
      hostname: "creator-without-node.example",
      role_assignment: ra,
      locale: "it"
    )

    assert_nil domain.node
    assert_equal ra, domain.role_assignment
    assert_includes ra.domains, domain
  end

  test "node must belong to the selected creator world" do
    first_user = User.create!(
      email_address: "first-domain-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    first_user.create_profile!(display_name: "First Owner")
    first_ra = RoleAssignment.create!(profile: first_user.profile, role: :creator_of_worlds)

    second_user = User.create!(
      email_address: "second-domain-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    second_user.create_profile!(display_name: "Second Owner")
    second_ra = RoleAssignment.create!(profile: second_user.profile, role: :creator_of_worlds)
    second_node = Node.create!(title: "Second Root", role_assignment: second_ra)

    domain = Domain.new(
      hostname: "wrong-node-owner.example",
      role_assignment: first_ra,
      node: second_node,
      locale: "it"
    )

    assert_not domain.valid?
    assert_includes domain.errors[:node_id], "deve appartenere allo stesso Creator del dominio"
  end

  test "imports a canonical domain linked through node slug" do
    user = User.create!(
      email_address: "node-slug-domain@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Node Slug Owner")
    assignment = RoleAssignment.create!(profile: user.profile, role: :ideatore)
    node = Node.create!(title: "Slug Brand", slug: "slug-brand", role_assignment: assignment)

    Domain.import_from_hash!(
      "slug-brand.example" => {
        "locale" => "it",
        "primary" => true,
        "node_slug" => "slug-brand"
      }
    )

    domain = Domain.find_by!(hostname: "slug-brand.example")
    assert_equal node, domain.node
    assert_equal "slug-brand", Domain.export_to_hash.dig("slug-brand.example", "node_slug")
    assert_not domain.settings.to_h.key?("node_slug")
  end
end
