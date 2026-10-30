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
    giardino_del_corpo = Node.find_by!(slug: "ilgiardinodelcorpo")
    genera_impresa = Node.find_by!(slug: "generaimpresa")
    inside_adventure = Node.find_by!(slug: "insideadventure")

    configured_slugs = %w[markpostura flowpulse rails4business posturacorretta stato-di-salute dalla-posturacorretta-al-giardino-del-corpo percorso-integrato ilgiardinodelcorpo insideadventure corpoecoscienza cantachetipassa generaimpresa impegno svuotamente brand-in-costruzione igiene-posturale radioestesia]
    assert_equal configured_slugs.size, first.nodes
    assert_equal configured_slugs.size, second.nodes
    assert_equal configured_slugs.size, Node.where(slug: configured_slugs).count
    assert mark.professional?
    assert_equal mark, user_profile.primary_node
    assert_equal mark, stato_di_salute.parent
    assert_equal stato_di_salute, linea_postura_giardino.parent
    assert_equal linea_postura_giardino, postura.parent
    assert_equal stato_di_salute, percorso_integrato.parent
    assert_equal linea_postura_giardino, giardino_del_corpo.parent
    assert_equal genera_impresa, inside_adventure.parent
    assert_equal mark, postura.professional_owner_node
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
