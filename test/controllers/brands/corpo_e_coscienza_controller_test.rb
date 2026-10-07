require "test_helper"

module Brands
  class CorpoECoscienzaControllerTest < ActionDispatch::IntegrationTest
    setup do
      user = User.create!(
        email_address: "corpo-coscienza-owner@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      profile = user.create_profile!(display_name: "Responsabile Corpo e Coscienza", username: "responsabile_cec")
      assignment = RoleAssignment.create!(profile: profile, role: :ideatore)
      @node = Node.create!(title: "Corpo e Coscienza", slug: "corpoecoscienza", role_assignment: assignment, status: "published")
      @domain = Domain.create!(
        hostname: "corpoecoscienza.org",
        locale: "it",
        target_controller: "brands/corpo_e_coscienza",
        target_action: "index",
        primary: true,
        active: true,
        node: @node
      )
    end

    test "shows the public method page and anonymous request form" do
      get corpo_e_coscienza_url

      assert_response :success
      assert_select "h1", "Corpo e Coscienza"
      assert_select ".cec-method-name", "Metodo Georges Courchinoux"
      assert_select "form[action='#{corpo_e_coscienza_requests_path}']"
      assert_select "#cec-professionals-map[data-professionals]"
      assert_select ".cec-request-tabs a", count: 3
      assert_select ".cec-request-mobile select option", count: 3
      assert_select "select[name='request[country_code]'] option[value='IT']", text: "Italia"
      assert_select "[data-controller='location-autocomplete']"
      assert_select ".cec-request-tab--professional.active", text: "Sono un professionista"
      assert_select "input[type='hidden'][name='request[request_kind]'][value='professional_application']"
      assert_includes response.body, "Crea il tuo percorso in gruppo"
      assert_includes response.body, "Trattamenti individuali"
      assert_includes response.body, "Georges Courchinoux"
      assert_includes response.body, "professionisti della salute e del benessere"
      assert_includes response.body, "Il Secondo e il Terzo Ciclo sono riservati ai professionisti della salute"
      assert_includes response.body, "cecgc@digicolorfree.net"
      assert_select "a[href='#{corpo_e_coscienza_privacy_path}']", text: "informativa privacy"
      assert_select "#metodo h2", text: "Le quattro direzioni di lavoro"
      assert_select ".cec-sticky-nav a[href='#metodo']", text: "Il metodo"
      assert_select ".cec-sticky-nav__brand[href='#top'] img[src*='logo-corpo-coscienza-quadrato.png']", count: 1
      assert_select "link[rel='icon'][href*='logo-corpo-coscienza-quadrato.png']"
      assert_select "link[rel='apple-touch-icon'][href*='logo-corpo-coscienza-quadrato.png']"
      assert_select "meta[property='og:image'][content*='logo-corpo-coscienza-quadrato.png']"
      assert_select "meta[name='twitter:image'][content*='logo-corpo-coscienza-quadrato.png']"
      assert_select ".cec-language-bar", count: 0
      assert_select ".cec-sticky-nav", text: /Il metodo.*Inizia un percorso.*Trova un professionista.*Formazione.*Contatti/m
      assert_select ".cec-sticky-nav", text: /Per le persone|Per i professionisti|Entra nella rete/, count: 0
      assert_select "#formazione a", text: "Sei già formato? Registrati"
      assert_select ".cec-sticky-nav a[href='#richiesta']", text: "Contatti"
      assert_select ".cec-training-program h1", text: "Piano di formazione"
      assert_select ".cec-training-program h2", text: "Primo Ciclo"
      assert_select ".cec-training-program", text: /12 meridiani principali.*Ritmologia stagionale.*Posture e autoposture/m
      assert_select ".privacy-center__banner[hidden]"
      assert_select ".privacy-center__dialog"
      assert_select "[data-privacy-placeholder='functionality']", text: /Carica la mappa/
      assert_select "[data-privacy-content='functionality'][hidden]#cec-professionals-map"
      assert_select "script[src*='unpkg.com/leaflet']", count: 0
      assert_select "template[data-privacy-src*='unpkg.com/leaflet']", count: 1
    end

    test "shows the privacy information for the request form" do
      get corpo_e_coscienza_privacy_url

      assert_response :success
      assert_select "h1", "Informativa sul trattamento dei dati personali"
      assert_select ".cec-prose", text: /articolo 13.*Regolamento UE 2016\/679/m
      assert_select "a[href='mailto:cecgc@digicolorfree.net']", text: "Contatta il responsabile"
      assert_select "a[href='#{corpo_e_coscienza_path(anchor: 'richiesta')}']", text: /Torna al modulo/
    end

    test "shows the page from the root of its dedicated domain" do
      host! "corpoecoscienza.org"
      get "/"

      assert_response :success
      assert_select "h1", "Corpo e Coscienza"
      assert_select ".cec-method-name", "Metodo Georges Courchinoux"
      assert_select "#cec-professionals-map[data-professionals]"
      assert_select "form[action='#{corpo_e_coscienza_requests_path}']"
    end

    test "preserves the originating section in the request form" do
      get corpo_e_coscienza_url(request_kind: "events", anchor: "richiesta")

      assert_response :success
      assert_select ".cec-request-tab.active", text: "Cerco un professionista"
      assert_select "input[type='hidden'][name='request[request_kind]'][value='events']"
    end

    test "professional tab starts with the directory application" do
      get corpo_e_coscienza_url(request_kind: "professional_application", anchor: "richiesta")

      assert_response :success
      assert_select ".cec-request-tab--professional.active", text: "Sono un professionista"
      assert_includes response.body, "Voglio essere inserito nell’elenco dei professionisti formati"
      assert_select "input[type='hidden'][name='request[request_kind]'][value='professional_application']"
    end

    test "records an anonymous request as contact and unscheduled commitment" do
      assert_difference -> { Brands::Impegno::Contact.count }, 1 do
        assert_difference -> { DataCommitment.count }, 1 do
          post corpo_e_coscienza_requests_url, params: {
            request: {
              request_kind: "find_professional",
              name: "Mario Rossi",
              email: "mario@example.com",
              phone: "",
              country_code: "IT",
              city: "Brescia",
              latitude: "45.5416",
              longitude: "10.2118",
              location_ref: "osm:R:44881",
              message: "Cerco un professionista nella mia zona.",
              privacy_consent: "1"
            }
          }
        end
      end

      commitment = DataCommitment.order(:created_at).last
      assert_redirected_to corpo_e_coscienza_path(anchor: "richiesta")
      assert_equal "requested", commitment.status
      assert_equal "service", commitment.kind
      assert_nil commitment.starts_at
      assert_not commitment.blocks_calendar?
      assert_equal @node, commitment.subject
      assert_equal "mario@example.com", commitment.participant_contact.email
      assert_equal "find_professional", commitment.metadata["request_kind"]
      assert_equal "IT", commitment.metadata["country_code"]
      assert_equal 45.5416, commitment.metadata["latitude"]
      assert_equal 10.2118, commitment.metadata["longitude"]
      assert_equal "osm:R:44881", commitment.metadata["location_ref"]
    end

    test "requires a contact channel" do
      assert_no_difference [-> { Brands::Impegno::Contact.count }, -> { DataCommitment.count }] do
        post corpo_e_coscienza_requests_url, params: {
          request: {
            request_kind: "information",
            name: "Mario Rossi",
            message: "Vorrei alcune informazioni.",
            privacy_consent: "1"
          }
        }
      end

      assert_redirected_to corpo_e_coscienza_path(anchor: "richiesta")
    end

    test "returns provider suggestions through the local endpoint" do
      suggestions = [{ label: "Brescia, Lombardia, Italia", city: "Brescia", country_code: "IT", latitude: 45.54, longitude: 10.21 }]

      with_location_search(->(**) { suggestions }) do
        get corpo_e_coscienza_locations_url, params: { q: "Bre", country_code: "IT" }, as: :json
      end

      assert_response :success
      assert_equal suggestions.as_json, response.parsed_body
    end

    test "does not query the provider before three characters" do
      with_location_search(->(**) { flunk "provider should not be called" }) do
        get corpo_e_coscienza_locations_url, params: { q: "Br", country_code: "IT" }, as: :json
      end

      assert_response :success
      assert_equal [], response.parsed_body
    end

    private

      def with_location_search(replacement)
        original = LocationSearch.method(:call)
        LocationSearch.singleton_class.send(:define_method, :call, replacement)
        yield
      ensure
        LocationSearch.singleton_class.send(:define_method, :call, original)
      end
  end
end
