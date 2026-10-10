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
end
