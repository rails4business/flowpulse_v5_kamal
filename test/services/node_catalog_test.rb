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
    ponte_prima_settimana = Node.find_by!(slug: "accesso-posturacorretta-da-prima-settimana")
    apprendimento_espressione = Node.find_by!(slug: "apprendimento-1-espressione")
    area_massaggio = Node.find_by!(slug: "area-massaggio-terapie-manuali-tecniche-corporee")
    apprendimento_consapevolezza = Node.find_by!(slug: "apprendimento-2-connessione")
    giardino_del_corpo = Node.find_by!(slug: "ilgiardinodelcorpo")
    genera_impresa = Node.find_by!(slug: "generaimpresa")
    inside_adventure = Node.find_by!(slug: "insideadventure")
    rails4business = Node.find_by!(slug: "rails4business")

    configured_slugs = %w[markpostura flowpulse rails4business posturacorretta stato-di-salute dalla-posturacorretta-al-giardino-del-corpo percorso-integrato stop-al-dolore prevenzione performance percorso-benessere accesso-posturacorretta-da-percorso-integrato apprendimento-1-espressione area-massaggio-terapie-manuali-tecniche-corporee apprendimento-2-connessione categorie-generali categorie-specifiche sessanta-movimenti-alla-scrivania la-prima-settimana-con-posturacorretta accesso-posturacorretta-da-prima-settimana pacchetto-gruppi ilgiardinodelcorpo accesso-stato-di-salute-da-posturacorretta accesso-stato-di-salute-da-giardino-del-corpo accesso-percorso-integrato-da-linea-postura-giardino insideadventure corpoecoscienza cantachetipassa generaimpresa impegno svuotamente brand-in-costruzione igiene-posturale radioestesia]
    assert_equal configured_slugs.size, first.nodes
    assert_equal configured_slugs.size, second.nodes
    assert_equal configured_slugs.size, Node.where(slug: configured_slugs).count
    assert mark.professional?
    assert_equal mark, user_profile.primary_node
    assert_equal mark, stato_di_salute.parent
    assert_equal stato_di_salute, linea_postura_giardino.parent
    assert_equal linea_postura_giardino, postura.parent
    assert_equal stato_di_salute, percorso_integrato.parent
    assert_equal percorso_integrato, Node.find_by!(slug: "stop-al-dolore").parent
    assert_equal percorso_integrato, Node.find_by!(slug: "percorso-benessere").parent
    assert_nil prima_settimana.link_node
    assert_not prima_settimana.bridge_node?
    assert_equal apprendimento_espressione, area_massaggio.parent
    assert_equal area_massaggio, prima_settimana.parent
    assert_equal prima_settimana, ponte_prima_settimana.parent
    assert_equal postura, ponte_prima_settimana.link_node
    assert ponte_prima_settimana.bridge_node?
    assert_nil Node.find_by(slug: "accesso-posturacorretta-da-stato-di-salute")
    assert_equal "access_bridge", Node.find_by!(slug: "accesso-posturacorretta-da-percorso-integrato").view_type
    assert_equal stato_di_salute, Node.find_by!(slug: "accesso-stato-di-salute-da-posturacorretta").parent
    assert_equal postura, Node.find_by!(slug: "accesso-stato-di-salute-da-posturacorretta").link_node
    assert_equal stato_di_salute, Node.find_by!(slug: "accesso-stato-di-salute-da-giardino-del-corpo").parent
    assert_equal giardino_del_corpo, Node.find_by!(slug: "accesso-stato-di-salute-da-giardino-del-corpo").link_node
    assert_equal percorso_integrato, Node.find_by!(slug: "accesso-percorso-integrato-da-linea-postura-giardino").link_node
    assert_equal "backlink_bridge", Node.find_by!(slug: "accesso-stato-di-salute-da-posturacorretta").view_type
    assert_equal Node.find_by!(slug: "categorie-specifiche"), Node.find_by!(slug: "sessanta-movimenti-alla-scrivania").parent
    assert_equal prima_settimana, Node.find_by!(slug: "pacchetto-gruppi").parent
    assert_equal linea_postura_giardino, giardino_del_corpo.parent
    assert_equal genera_impresa, inside_adventure.parent
    assert_equal mark, postura.professional_owner_node
    assert_equal "#2563EB", postura.map_color
    assert_equal "#2E1065", apprendimento_espressione.map_color
    assert_equal "Apprendimento 2 · Consapevolezza con le metodiche posturali", apprendimento_consapevolezza.title
    assert_equal "#4F46E5", apprendimento_consapevolezza.map_color
    assert_equal "#2E1065", prima_settimana.map_color
    assert_equal prima_settimana, Node.find_by!(slug: "igiene-posturale").parent
    assert_equal "published", Node.find_by!(slug: "igiene-posturale").status
    assert_equal "#7C3AED", linea_postura_giardino.map_color
    assert_equal "#7C3AED", giardino_del_corpo.map_color
    assert_equal "Apprendimento 3 · Connessione — Il Giardino del Corpo", giardino_del_corpo.title
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
