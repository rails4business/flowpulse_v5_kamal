require "test_helper"

class RoleDefinitions::RegistryTest < ActiveSupport::TestCase
  test "canonicalizes the legacy GeneraImpresa role" do
    assert_equal "imprenditore_generaimpresa", RoleDefinitions::Registry.canonical_code("creator_generaimpresa")
    assert_equal "Imprenditore GeneraImpresa", RoleDefinitions::Registry.fetch("creator_generaimpresa").label
  end

  test "checks the role against its brand" do
    genera_impresa = Node.new(slug: "generaimpresa")
    postura_corretta = Node.new(slug: "posturacorretta")

    assert RoleDefinitions::Registry.compatible_with_brand?("imprenditore_generaimpresa", genera_impresa)
    assert_not RoleDefinitions::Registry.compatible_with_brand?("imprenditore_generaimpresa", postura_corretta)
  end

  test "limits the GeneraImpresa entrepreneur to seven managed nodes without role delegation" do
    definition = RoleDefinitions::Registry.fetch("imprenditore_generaimpresa")

    assert_not definition.delegatable
    assert_empty definition.delegatable_role_codes
    assert_equal 7, definition.limits.fetch(:managed_nodes_per_brand)
  end

  test "defines the GeneraImpresa manager without role delegation" do
    definition = RoleDefinitions::Registry.fetch("gestore_generaimpresa")

    assert_equal "Gestore GeneraImpresa", definition.label
    assert_includes definition.capabilities, :manage_requests
    assert_includes definition.capabilities, :manage_access
    assert_not definition.delegatable
  end
end
