require "test_helper"

class DomainArchitectureAuditTest < ActiveSupport::TestCase
  test "reports missing node entrypoint and public metadata without changing the domain" do
    domain = Domain.create!(hostname: "incomplete.example", locale: "it")

    result = DomainArchitectureAudit.new([domain], site_configs: {}).call
    codes = result.issues_for(domain).map(&:code)

    assert_includes codes, :missing_node
    assert_includes codes, :missing_entrypoint
    assert_includes codes, :missing_metadata
    assert_nil domain.reload.node_id
  end

  test "accepts a complete domain using an existing editorial site" do
    domain = Domain.create!(
      hostname: "complete.example",
      locale: "it",
      site_key: "complete_it",
      site_title: "Complete",
      site_description: "Descrizione completa",
      favicon_url: "https://cdn.example/favicon.png",
      social_image_url: "https://cdn.example/social.png"
    )

    result = DomainArchitectureAudit.new(
      [domain],
      site_configs: { "complete_it" => { "node_slug" => "complete", "locale" => "it" } }
    ).call

    assert_includes result.issues_for(domain).map(&:code), :missing_node
  end

  test "checks aliases and primary domains per node and locale" do
    creator = RoleAssignment.create!(
      profile: User.create!(email_address: "domain-audit@example.com", password: "password123").create_profile!(display_name: "Domain Audit"),
      role: :ideatore
    )
    node = Node.create!(title: "Audit Brand", role_assignment: creator)
    first = Domain.create!(hostname: "first.example", locale: "it", node: node, primary: true, target_controller: "landing", target_action: "flowpulse")
    second = Domain.create!(hostname: "second.example", locale: "it", node: node, primary: true, target_controller: "landing", target_action: "flowpulse")
    orphan_alias = Domain.create!(hostname: "www.orphan.example", canonical_host: "orphan.example", locale: "it", primary: true)

    result = DomainArchitectureAudit.new([first, second, orphan_alias], site_configs: {}).call

    assert_includes result.issues_for(first).map(&:code), :multiple_primary
    assert_includes result.issues_for(second).map(&:code), :multiple_primary
    assert_includes result.issues_for(orphan_alias).map(&:code), :missing_canonical
    assert_includes result.issues_for(orphan_alias).map(&:code), :primary_alias
  end


  test "checks that Site and Domain refer to the same Node and locale" do
    creator = RoleAssignment.create!(
      profile: User.create!(email_address: "domain-site-audit@example.com", password: "password123").create_profile!(display_name: "Domain Site Audit"),
      role: :ideatore
    )
    node = Node.create!(title: "Actual Brand", slug: "actual-brand", role_assignment: creator)
    domain = Domain.create!(
      hostname: "site-mismatch.example",
      locale: "it",
      node: node,
      site_key: "other_site",
      target_controller: "landing",
      target_action: "flowpulse"
    )

    result = DomainArchitectureAudit.new(
      [domain],
      site_configs: { "other_site" => { "node_slug" => "other-brand", "locale" => "en" } }
    ).call
    codes = result.issues_for(domain).map(&:code)

    assert_includes codes, :site_node_mismatch
    assert_includes codes, :site_locale_mismatch
  end

  test "warns when an active canonical domain is excluded from public discovery" do
    profile = User.create!(email_address: "domain-discovery-audit@example.com", password: "password123").create_profile!(display_name: "Discovery Audit")
    creator = RoleAssignment.create!(profile:, role: :ideatore)
    node = Node.create!(title: "Draft Brand", role_assignment: creator, status: "draft", visibility: "public")
    domain = Domain.create!(hostname: "draft-brand.example", locale: "it", node:, target_controller: "landing", target_action: "flowpulse")

    codes = DomainArchitectureAudit.new([domain], site_configs: {}).call.issues_for(domain).map(&:code)

    assert_includes codes, :excluded_from_public_discovery
  end
end
