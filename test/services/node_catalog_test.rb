require "test_helper"

class NodeCatalogTest < ActiveSupport::TestCase
  setup do
    user = User.create!(
      email_address: "markpostura-catalog@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Mark Postura", username: "markpostura")
    RoleAssignment.create!(profile: user.profile, role: :ideatore)
  end

  test "imports the configured hierarchy and is idempotent" do
    catalog = NodeCatalog.from_config("test")

    first = catalog.import!
    second = catalog.import!

    mark = Node.find_by!(slug: "markpostura")
    stato_di_salute = Node.find_by!(slug: "stato-di-salute")
    linea_postura_giardino = Node.find_by!(slug: "dalla-posturacorretta-al-giardino-del-corpo")
    postura = Node.find_by!(slug: "posturacorretta")
    percorso_integrato = Node.find_by!(slug: "percorso-integrato")
    prima_settimana = Node.find_by!(slug: "la-prima-settimana-con-posturacorretta")
    igiene_posturale_landing = Node.find_by!(slug: "igieneposturale")
    igiene_posturale_course = Node.find_by!(slug: "igiene-posturale")
    ponte_igiene_posturale = Node.find_by!(slug: "accesso-corso-igiene-posturale-da-landing")
    apprendimento_espressione = Node.find_by!(slug: "apprendimento-1-espressione")
    postura_fisiologia = Node.find_by!(slug: "postura-e-fisiologia")
    area_massaggio = Node.find_by!(slug: "area-massaggio-terapie-manuali-tecniche-corporee")
    apprendimento_consapevolezza = Node.find_by!(slug: "apprendimento-2-connessione")
    metodiche_posturali = Node.find_by!(slug: "metodiche-posturali")
    giardino_del_corpo = Node.find_by!(slug: "ilgiardinodelcorpo")
    genera_impresa = Node.find_by!(slug: "generaimpresa")
    inside_adventure = Node.find_by!(slug: "insideadventure")
    rails4business = Node.find_by!(slug: "rails4business")
    professionisti_salute = Node.find_by!(slug: "professionisti-salute-patologie-sintomi")
    professionisti_benessere = Node.find_by!(slug: "professionisti-benessere-prevenzione-qualita-vita")
    educazione_salute = Node.find_by!(slug: "educazione-alla-salute")
    paradigmi_cura = Node.find_by!(slug: "paradigmi-scelta-cura")
    inizia_percorso = Node.find_by!(slug: "inizia-percorso-integrato")
    educazione_metodiche = Node.find_by!(slug: "educazione-alla-salute-metodiche-posturali")
    con_chi_iniziare = Node.find_by!(slug: "con-chi-iniziare")
    linee_guida = Node.find_by!(slug: "linee-guida-percorso-integrato")
    questionario_salute = Node.find_by!(slug: "questionario-orientamento-stato-di-salute")

    configured_slugs = YAML.load_file(Rails.root.join("config/nodes.yml"), aliases: true).dig("test", "nodes").keys
    assert_equal configured_slugs.size, first.nodes
    assert_equal configured_slugs.size, second.nodes
    assert_equal configured_slugs.size, Node.where(slug: configured_slugs).count
    assert mark.professional?
    assert_equal mark, user_profile.primary_node
    assert_equal inizia_percorso, stato_di_salute.parent
    assert_equal postura, linea_postura_giardino.parent
    assert_equal mark, postura.parent
    assert_equal mark, percorso_integrato.parent
    assert_equal percorso_integrato, paradigmi_cura.parent
    assert_equal percorso_integrato, con_chi_iniziare.parent
    assert con_chi_iniziare.lane_container?
    assert_equal percorso_integrato, linee_guida.parent
    assert_equal percorso_integrato, inizia_percorso.parent
    assert_equal con_chi_iniziare, professionisti_salute.parent
    assert_equal con_chi_iniziare, professionisti_benessere.parent
    assert_equal con_chi_iniziare, educazione_salute.parent
    assert_equal stato_di_salute, questionario_salute.parent
    assert questionario_salute.lane_container?
    assert_equal questionario_salute, Node.find_by!(slug: "stop-al-dolore").parent
    assert_equal Node.find_by!(slug: "stop-al-dolore"), Node.find_by!(slug: "prevenzione").parent
    assert_equal "Prevenzione e rischi della tua attività principale", Node.find_by!(slug: "prevenzione").title
    assert_equal Node.find_by!(slug: "prevenzione"), Node.find_by!(slug: "performance").parent
    assert_equal "Performance e risorse", Node.find_by!(slug: "performance").title
    assert_equal Node.find_by!(slug: "performance"), Node.find_by!(slug: "percorso-benessere").parent
    assert_equal Node.find_by!(slug: "percorso-benessere"), educazione_metodiche.parent
    assert_nil prima_settimana.link_node
    assert_not prima_settimana.bridge_node?
    assert prima_settimana.lane_container?
    introduzione_fisiologia = Node.find_by!(slug: "introduzione-postura-e-fisiologia")
    assert_equal postura_fisiologia, introduzione_fisiologia.parent
    assert_equal introduzione_fisiologia, area_massaggio.parent
    assert_equal introduzione_fisiologia, Node.find_by!(slug: "accesso-area-movimento-da-prima-settimana").parent
    assert_nil Node.find_by(slug: "accesso-area-massaggio-da-postura-e-fisiologia")
    assert_equal "course_lesson", area_massaggio.view_type
    assert_equal 1, area_massaggio.position
    movimento = Node.find_by!(slug: "area-movimento-postura-attivita-motoria")
    mente = Node.find_by!(slug: "area-mente-postura-ascolto-consapevolezza")
    alimentazione = Node.find_by!(slug: "area-alimentazione-postura-nutrimento-fisiologia")
    farmaci = Node.find_by!(slug: "area-farmaci-postura-regolazione-medicamenti")
    assert_equal area_massaggio, movimento.parent
    assert_equal movimento, mente.parent
    percorso_salute = Node.find_by!(slug: "percorso-salute-nutrire-il-corpo")
    assert_equal mente, percorso_salute.parent
    assert_equal percorso_salute, alimentazione.parent
    assert_equal percorso_salute, farmaci.parent
    assert [movimento, mente, alimentazione, farmaci].all? { |node| node.view_type == "course_lesson" }
    introduzione = Node.find_by!(slug: "introduzione-al-percorso-integrato")
    assert_equal apprendimento_espressione, introduzione.parent
    assert_equal introduzione, prima_settimana.parent
    assert_equal "course_lesson", prima_settimana.view_type
    assert_nil Node.find_by(slug: "lezione-1-inizia-con-posturacorretta")
    assert_equal postura, apprendimento_espressione.parent
    assert_equal postura, apprendimento_consapevolezza.parent
    assert_nil Node.find_by(slug: "accesso-posturacorretta-da-prima-settimana")
    assert_nil Node.find_by(slug: "accesso-posturacorretta-da-stato-di-salute")
    percorso_bridge = Node.find_by!(slug: "accesso-posturacorretta-da-percorso-integrato")
    assert_equal "access_bridge", percorso_bridge.view_type
    assert_equal educazione_metodiche, percorso_bridge.parent
    assert_equal postura_fisiologia, percorso_bridge.link_node
    assert_nil Node.find_by(slug: "accesso-stato-di-salute-da-posturacorretta")
    assert_nil Node.find_by(slug: "accesso-stato-di-salute-da-giardino-del-corpo")
    assert_nil Node.find_by(slug: "accesso-percorso-integrato-da-linea-postura-giardino")
    assert_equal %w[questionario-orientamento-stato-di-salute comuni centri professioni scuole-formazione-professionisti], stato_di_salute.children.order(:position).pluck(:slug)
    assert_equal "Attività generali · Servizi settimanali", Node.find_by!(slug: "categorie-generali").title
    assert Node.find_by!(slug: "categorie-generali").lane_container?
    assert_equal "Attività specifiche · Percorsi mirati", Node.find_by!(slug: "categorie-specifiche").title
    assert Node.find_by!(slug: "categorie-specifiche").lane_container?
    assert_equal Node.find_by!(slug: "categorie-generali"), Node.find_by!(slug: "condizioni-e-patologie").parent
    assert_equal "Condizioni", Node.find_by!(slug: "condizioni-e-patologie").title
    assert_equal Node.find_by!(slug: "categorie-generali"), Node.find_by!(slug: "eta").parent
    assert_equal Node.find_by!(slug: "categorie-specifiche"), Node.find_by!(slug: "attivita-e-contesti").parent
    assert_equal apprendimento_consapevolezza, Node.find_by!(slug: "metodiche-posturali").parent
    assert_equal 3, Node.find_by!(slug: "metodiche-posturali").position
    assert Node.find_by!(slug: "metodiche-posturali").lane_container?
    assert_equal 10, metodiche_posturali.children.size
    assert_equal %w[fisioterapia gds osteopatia mezieres rpg souchard feldenkrais alexander kinesiologia-applicata bioritmi-corpo-coscienza], metodiche_posturali.children.order(:position).pluck(:slug)
    assert metodiche_posturali.children.all? { |node| node.view_type == "methodology" }
    methodology_course_bridges = {
      "accesso-fisioterapia-da-primo-incontro" => ["principi-di-fisioterapia", "fisioterapia"],
      "accesso-gds-da-primo-incontro" => ["biomeccanica-comportamentale-gds", "gds"],
      "accesso-osteopatia-da-primo-incontro" => ["principi-di-osteopatia", "osteopatia"],
      "accesso-corpo-coscienza-da-primo-incontro" => ["introduzione-al-metodo-corpo-e-coscienza", "bioritmi-corpo-coscienza"],
      "accesso-kinesiologia-da-primo-incontro" => ["introduzione-alla-kinesiologia-applicata", "kinesiologia-applicata"],
      "accesso-categoria-metodiche-da-altre-metodiche" => ["altre-metodiche-posturali", "metodiche-posturali"]
    }
    methodology_course_bridges.each do |bridge_slug, targets|
      course_slug, methodology_slug = targets
      bridge = Node.find_by!(slug: bridge_slug)
      assert_equal "access_bridge", bridge.view_type
      assert_equal course_slug, bridge.parent.slug
      assert_equal methodology_slug, bridge.link_node.slug
      assert bridge.bridge_node?
    end
    assert_nil Node.find_by(slug: "conosci-gds-con-posturacorretta")
    assert_nil Node.find_by(slug: "conosci-feldenkrais-con-posturacorretta")
    assert_empty Node.find_by!(slug: "mezieres").children
    assert_empty Node.find_by!(slug: "rpg").children
    assert_empty Node.find_by!(slug: "souchard").children
    assert_equal Node.find_by!(slug: "attivita-e-contesti"), Node.find_by!(slug: "sessanta-movimenti-alla-scrivania").parent
    servizi_personalizzati = Node.find_by!(slug: "pacchetto-gruppi")
    individuali = Node.find_by!(slug: "servizi-personalizzati-individuali")
    assert_equal apprendimento_espressione, servizi_personalizzati.parent
    assert_equal %w[introduzione-al-percorso-integrato pacchetto-gruppi], apprendimento_espressione.children.order(:position).pluck(:slug)
    assert_equal "Servizi personalizzati", servizi_personalizzati.title
    assert servizi_personalizzati.lane_container?
    assert_equal servizi_personalizzati, individuali.parent
    assert individuali.lane_container?
    assert_equal individuali, Node.find_by!(slug: "trattamento-singolo").parent
    assert_equal individuali, Node.find_by!(slug: "pacchetto-percorso-singolo").parent
    assert_equal servizi_personalizzati, Node.find_by!(slug: "percorso-aziende-associazioni-sportive").parent
    assert_equal linea_postura_giardino, giardino_del_corpo.parent
    assert_equal genera_impresa, inside_adventure.parent
    assert_equal mark, postura.professional_owner_node
    assert_equal "#2563EB", postura.map_color
    assert_equal "Educazione 1 · Come si esprime il corpo", apprendimento_espressione.title
    assert_equal "#38BDF8", apprendimento_espressione.map_color
    assert apprendimento_espressione.lane_container?
    assert_equal prima_settimana, postura_fisiologia.parent
    assert_equal "course", postura_fisiologia.view_type
    assert_equal postura, Node.find_by!(slug: "diventa-insegnante-posturacorretta").parent
    assert_equal "Educazione 2 · Consapevolezza con le metodiche posturali", apprendimento_consapevolezza.title
    assert_equal "#4F46E5", apprendimento_consapevolezza.map_color
    assert apprendimento_consapevolezza.lane_container?
    assert_equal "Educazione 3 · Connessione dalla PosturaCorretta al Giardino del Corpo", linea_postura_giardino.title
    assert linea_postura_giardino.lane_container?
    assert_equal "#2E1065", prima_settimana.map_color
    assert_equal mark, igiene_posturale_landing.parent
    assert_equal "published", igiene_posturale_course.status
    assert_equal igiene_posturale_landing, ponte_igiene_posturale.parent
    assert_equal igiene_posturale_course, ponte_igiene_posturale.link_node
    assert ponte_igiene_posturale.bridge_node?
    valutazione_mobilita = Node.find_by!(slug: "valutazione-mobilita-articolare")
    assert_nil Node.find_by(slug: "area-massaggio-orientarsi")
    assert_equal "course_lesson", area_massaggio.view_type
    assert_equal Node.find_by!(slug: "posturacorretta"), valutazione_mobilita.parent
    assert_empty valutazione_mobilita.line_slugs
    assert_equal area_massaggio, igiene_posturale_course.parent
    assert_equal ["postura-recupero"], prima_settimana.line_slugs
    assert_equal %w[prima-settimana-posturacorretta igiene-posturale area-massaggio-recupero], prima_settimana.offer_slugs
    assert_equal ["postura-recupero"], area_massaggio.line_slugs
    assert_equal %w[igiene-posturale area-massaggio-recupero], igiene_posturale_course.offer_slugs
    igiene_posturale_intro = Node.find_by!(slug: "igiene-posturale-introduzione")
    assert_equal igiene_posturale_course, igiene_posturale_intro.parent
    assert_equal "course_lesson", igiene_posturale_intro.view_type
    assert_equal igiene_posturale_intro, Node.find_by!(slug: "igiene-posturale-mobilita-articolare").parent
    assert_equal Node.find_by!(slug: "igiene-posturale-mobilita-articolare"), Node.find_by!(slug: "igiene-posturale-punti-di-tensione").parent
    assert_equal Node.find_by!(slug: "igiene-posturale-punti-di-tensione"), Node.find_by!(slug: "igiene-posturale-vie-di-discesa").parent
    assert_equal 7, Node.find_by!(slug: "igiene-posturale-mobilita-articolare").position
    assert igiene_posturale_course.lane_container?
    assert_equal "course", igiene_posturale_course.view_type
    assert_equal "course", Node.find_by!(slug: "principi-di-fisioterapia").view_type
    assert_equal "Principi di Fisioterapia", Node.find_by!(slug: "principi-di-fisioterapia").title
    assert_equal "course", Node.find_by!(slug: "biomeccanica-comportamentale-gds").view_type
    assert_equal "Introduzione alla biomeccanica comportamentale (GDS)", Node.find_by!(slug: "biomeccanica-comportamentale-gds").title
    assert_equal Node.find_by!(slug: "igiene-posturale-recettori-sensoriali"), Node.find_by!(slug: "principi-di-fisioterapia").parent
    assert_equal Node.find_by!(slug: "principi-di-fisioterapia"), Node.find_by!(slug: "principi-di-fisioterapia-introduzione-riabilitazione-sistemi").parent
    assert_equal Node.find_by!(slug: "principi-di-fisioterapia-introduzione-riabilitazione-sistemi"), Node.find_by!(slug: "principi-di-fisioterapia-sistema-respiratorio").parent
    assert_equal Node.find_by!(slug: "principi-di-fisioterapia-sistema-respiratorio"), Node.find_by!(slug: "principi-di-fisioterapia-sistema-nervoso-urogenitale").parent
    assert Node.find_by!(slug: "principi-di-fisioterapia").lane_container?
    assert_equal Node.find_by!(slug: "principi-di-fisioterapia-sistema-linfatico-digerente"), Node.find_by!(slug: "biomeccanica-comportamentale-gds").parent
    assert_equal Node.find_by!(slug: "biomeccanica-comportamentale-gds"), Node.find_by!(slug: "biomeccanica-comportamentale-gds-cinque-direzioni-movimento").parent
    assert_equal Node.find_by!(slug: "biomeccanica-comportamentale-gds-cinque-direzioni-movimento"), Node.find_by!(slug: "biomeccanica-comportamentale-gds-catena-am").parent
    assert Node.find_by!(slug: "biomeccanica-comportamentale-gds").lane_container?
    assert_equal "Principi di Osteopatia", Node.find_by!(slug: "principi-di-osteopatia").title
    assert_equal Node.find_by!(slug: "biomeccanica-comportamentale-gds-catene-pa-ap"), Node.find_by!(slug: "principi-di-osteopatia").parent
    assert_equal Node.find_by!(slug: "principi-di-osteopatia"), Node.find_by!(slug: "principi-di-osteopatia-disfunzioni-cosa-sono").parent
    assert_equal Node.find_by!(slug: "principi-di-osteopatia-disfunzioni-cosa-sono"), Node.find_by!(slug: "principi-di-osteopatia-sistema-fasciale").parent
    assert_equal Node.find_by!(slug: "principi-di-osteopatia-sistema-neurovegetativo"), Node.find_by!(slug: "principi-di-osteopatia-introduzione-pnei").parent
    assert Node.find_by!(slug: "principi-di-osteopatia").lane_container?
    assert_equal "Introduzione al metodo Corpo e Coscienza", Node.find_by!(slug: "introduzione-al-metodo-corpo-e-coscienza").title
    assert_equal Node.find_by!(slug: "principi-di-osteopatia-introduzione-pnei"), Node.find_by!(slug: "introduzione-al-metodo-corpo-e-coscienza").parent
    assert_equal Node.find_by!(slug: "introduzione-al-metodo-corpo-e-coscienza"), Node.find_by!(slug: "introduzione-al-metodo-corpo-e-coscienza-due-circolazioni").parent
    assert_equal Node.find_by!(slug: "introduzione-al-metodo-corpo-e-coscienza-due-circolazioni"), Node.find_by!(slug: "introduzione-al-metodo-corpo-e-coscienza-tre-centri-gravita").parent
    introduzione_kinesiologia = Node.find_by!(slug: "introduzione-alla-kinesiologia-applicata")
    assert Node.find_by!(slug: "introduzione-al-metodo-corpo-e-coscienza").lane_container?
    assert_equal Node.find_by!(slug: "introduzione-al-metodo-corpo-e-coscienza-sette-centri-neurolinfatici"), introduzione_kinesiologia.parent
    assert_equal "Introduzione alla Kinesiologia Applicata", introduzione_kinesiologia.title
    assert introduzione_kinesiologia.lane_container?
    assert_equal introduzione_kinesiologia, Node.find_by!(slug: "introduzione-kinesiologia-sequenza").parent
    assert_equal Node.find_by!(slug: "introduzione-kinesiologia-sequenza"), Node.find_by!(slug: "altre-metodiche-posturali").parent
    assert Node.find_by!(slug: "altre-metodiche-posturali").lane_container?
    assert_equal "Altre metodiche posturali", Node.find_by!(slug: "altre-metodiche-posturali").title
    assert_empty Node.where(slug: YAML.load_file(Rails.root.join("config/nodes.yml"), aliases: true).dig("test", "removed_slugs"))
    assert_nil Node.find_by(slug: "altre-metodiche-posturali-feldenkrais")
    assert_equal "#7C3AED", linea_postura_giardino.map_color
    assert_equal "#7C3AED", giardino_del_corpo.map_color
    assert_equal "Il Giardino del Corpo", giardino_del_corpo.title
    assert_equal linea_postura_giardino, rails4business.parent
    assert_equal "#F59E0B", rails4business.map_color
    assert_equal mark, Node.find_by!(slug: "flowpulse").parent
    assert_match(/Piattaforma trasversale/, Node.find_by!(slug: "flowpulse").description)
    assert_match(/costruzione di processi/, Node.find_by!(slug: "rails4business").description)
    assert_match(/diventano progetti/, genera_impresa.description)
    assert_match(/calendari, eventi ed esperienze/, Node.find_by!(slug: "impegno").description)
  end

  test "supports a professional demo without a profile association" do
    assignment = RoleAssignment.joins(:profile).find_by!(profiles: { username: "markpostura" })
    catalog = NodeCatalog.new(
      "nodes" => {
        "demo-professional" => {
          "title" => "Professionista non iscritto",
          "node_type" => "professional",
          "owner_username" => "markpostura"
        }
      }
    )

    catalog.import!
    node = Node.find_by!(slug: "demo-professional")

    assert node.professional?
    assert_nil node.primary_professional_profile
    assert_equal assignment, node.role_assignment
  end

  test "renames configured legacy slugs without duplicating the node" do
    assignment = RoleAssignment.joins(:profile).find_by!(profiles: { username: "markpostura" })
    legacy = Node.create!(
      title: "Vecchio incontro Kinesiologia",
      slug: "primo-incontro-kinesiologia-applicata",
      role_assignment: assignment
    )

    NodeCatalog.from_config("test").import!

    assert_equal legacy.id, Node.find_by!(slug: "introduzione-alla-kinesiologia-applicata").id
    assert_nil Node.find_by(slug: "primo-incontro-kinesiologia-applicata")
  end

  test "clears lines and offers no longer declared in the catalog" do
    catalog = NodeCatalog.from_config("test")
    catalog.import!
    Node.find_by!(slug: "valutazione-mobilita-articolare").update!(line_slugs: ["postura-recupero"], offer_slugs: ["igiene-posturale"])

    catalog.import!

    node = Node.find_by!(slug: "valutazione-mobilita-articolare")
    assert_empty node.line_slugs
    assert_empty node.offer_slugs
  end

  test "dry run validates without persisting nodes" do
    catalog = NodeCatalog.from_config("test")

    assert_no_difference("Node.count") { catalog.import!(dry_run: true) }
  end

  test "optional pruning removes nodes absent from the catalog outside production" do
    catalog = NodeCatalog.from_config("test")
    catalog.import!
    extra = Node.create!(
      title: "Node locale temporaneo",
      slug: "node-locale-temporaneo",
      role_assignment: RoleAssignment.joins(:profile).find_by!(profiles: { username: "markpostura" })
    )

    result = catalog.import!(prune: true)

    assert_equal 1, result.pruned
    assert_not Node.exists?(extra.id)
  end

  private

    def user_profile
      Profile.find_by!(username: "markpostura")
    end
end
