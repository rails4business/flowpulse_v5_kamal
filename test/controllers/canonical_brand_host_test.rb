require "test_helper"

class CanonicalBrandHostTest < ActionDispatch::IntegrationTest
  test "redirects a GeneraImpresa path opened on the PosturaCorretta domain" do
    host! "posturacorretta.org"

    get "/generaimpresa/brand/davide-cattaneo"

    assert_redirected_to "http://generaimpresa.it/generaimpresa/brand/davide-cattaneo"
    assert_response :moved_permanently
  end

  test "keeps a branded path on its canonical domain" do
    host! "generaimpresa.it"

    get "/generaimpresa/brand/davide-cattaneo"

    assert_redirected_to "https://percorsointegrato.it/percorso-integrato/professionisti/davide-cattaneo"
  end

  test "moves the former Davide brand page to Percorso Integrato on localhost" do
    host! "localhost"

    get "/generaimpresa/brand/davide-cattaneo"

    assert_redirected_to "/percorso-integrato/professionisti/davide-cattaneo"
  end

  test "keeps the Impegno service on the Brand domain that is using it" do
    profile_user = User.create!(
      email_address: "postura-impegno-service@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    profile = profile_user.create_profile!(display_name: "Postura Impegno", username: "postura_impegno_service")
    owner = RoleAssignment.create!(profile:, role: :ideatore)
    node = Node.create!(title: "PosturaCorretta", slug: "posturacorretta", role_assignment: owner, node_type: :project)
    domain = Domain.create!(
      hostname: "posturacorretta.org",
      node:,
      locale: "it",
      primary: true,
      active: true,
      auth_slug: "posturacorretta"
    )
    BrandAccess.create!(profile:, brand_node: node, source_domain: domain, status: :active, joined_at: Time.current)
    host! "posturacorretta.org"
    post session_url, params: { email_address: profile_user.email_address, password: "password123" }

    get impegno_agenda_url(workspace: "1", default_brand: "posturacorretta")

    assert_response :success
    assert_equal "posturacorretta.org", request.host
  end

  test "still sends the standalone Impegno product to its canonical domain" do
    host! "posturacorretta.org"

    get impegno_url

    assert_redirected_to "http://1impegno.it/impegno"
    assert_response :moved_permanently
  end
end
