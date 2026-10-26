require "test_helper"

class DomainPublicationAuditTest < ActiveSupport::TestCase
  setup do
    profile = User.create!(email_address: "publication-audit@example.com", password: "password123").create_profile!(display_name: "Publication Audit")
    @owner = RoleAssignment.create!(profile:, role: :ideatore)
    @node = Node.create!(title: "Ready Brand", slug: "ready-brand", role_assignment: @owner, status: "published", visibility: "public")
    @domain = Domain.create!(
      hostname: "ready.example",
      locale: "it",
      node: @node,
      target_controller: "landing",
      target_action: "flowpulse",
      site_title: "Ready Brand",
      site_description: "Descrizione pubblica del dominio.",
      logo_square_url: "https://cdn.example/logo.png",
      favicon_url: "https://cdn.example/favicon.png",
      social_image_url: "https://cdn.example/social.png",
      security_profile: "standard"
    )
  end

  test "a complete public domain is ready" do
    result = audit(@domain, baseline: { "status" => "measured" })

    assert result.ready?
    assert result.checks.all?(&:ready?)
    assert_includes result.checks.map(&:key), :sitemap
    assert_includes result.checks.map(&:key), :llms
    assert_includes result.checks.map(&:key), :api
    assert_includes result.checks.map(&:key), :security
  end

  test "a private root blocks public discovery checks" do
    @node.update!(status: "draft", visibility: "private")

    result = audit(@domain, baseline: { "status" => "measured" })

    assert result.blocked?
    assert_equal :blocked, result.checks.find { |check| check.key == :node_visibility }.status
    assert_equal :blocked, result.checks.find { |check| check.key == :api }.status
  end

  test "missing metadata and a pending PageSpeed baseline require attention" do
    @domain.update!(site_description: nil, favicon_url: nil)

    result = audit(@domain, baseline: { "status" => "pending" }, pages: [{ "path" => "/" }])

    assert result.attention?
    assert_equal :warning, result.checks.find { |check| check.key == :identity }.status
    assert_equal :warning, result.checks.find { |check| check.key == :assets }.status
    assert_equal :warning, result.checks.find { |check| check.key == :performance }.status
  end

  test "an alias only checks activation and its canonical redirect" do
    domain_alias = Domain.create!(hostname: "www.ready.example", canonical_host: @domain.hostname, locale: "it")

    result = DomainPublicationAudit.new(domain_alias, domains: [@domain, domain_alias], performance_document: {}).call

    assert result.ready?
    assert_equal %i[active canonical], result.checks.map(&:key)
  end

  private
    def audit(domain, baseline:, pages: [])
      performance_document = {
        "domains" => {
          domain.hostname => {
            "pages" => pages,
            "baseline" => baseline
          }
        }
      }
      DomainPublicationAudit.new(domain, domains: [domain], performance_document:).call
    end
end
