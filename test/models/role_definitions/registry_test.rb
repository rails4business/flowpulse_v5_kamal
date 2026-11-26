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

    assert_empty definition.delegatable_role_codes
    assert_equal 7, definition.limits.fetch(:managed_nodes_per_brand)
  end

  test "defines the GeneraImpresa manager without role delegation" do
    definition = RoleDefinitions::Registry.fetch("gestore_generaimpresa")

    assert_equal "Gestore GeneraImpresa", definition.label
    assert_includes definition.capabilities, :manage_requests
    assert_includes definition.capabilities, :manage_access
    assert_empty definition.delegatable_role_codes
  end

  test "ordinary users and system privileges are not contextual role definitions" do
    %w[utente traveler superadmin unknown_role].each do |code|
      assert_not RoleDefinitions::Registry.registered?(code)
      assert_not RoleDefinitions::Registry.compatible_with_brand?(code, Node.new(slug: "generaimpresa"))
    end
  end

  test "shared secretary role is reserved and cannot be assigned yet" do
    definition = RoleDefinitions::Registry.fetch("segreteria")
    brand = Node.new(slug: "generaimpresa")

    assert_equal :shared, definition.scope
    assert_not definition.enabled
    assert_not RoleDefinitions::Registry.compatible_with_brand?(definition.code, brand)
    assert_not_includes RoleDefinitions::Registry.for_brand(brand), definition
  end

  test "brand roles require an explicit brand list" do
    definition = RoleDefinitions::Registry.fetch("insegnante_posturacorretta")

    assert_raises(ArgumentError) { definition.with(brand_slugs: []) }
    assert_raises(ArgumentError) { definition.with(scope: :system) }
    assert_not definition.compatible_with_brand?(nil)
  end

  test "role definitions cannot acquire permissions through mutable configuration" do
    definition = RoleDefinitions::Registry.fetch("imprenditore_generaimpresa")

    assert_raises(FrozenError) { definition.capabilities << :delegate_role }
    assert_raises(FrozenError) { definition.delegatable_role_codes << "gestore_generaimpresa" }
    assert_raises(FrozenError) { definition.brand_slugs.first.replace("posturacorretta") }
    assert_raises(FrozenError) { definition.limits[:managed_nodes_per_brand] = 100 }
  end

  test "delegation is an explicit list and does not require possessing the target capability" do
    teacher = RoleDefinitions::Registry.fetch("insegnante_posturacorretta")
    trainer = teacher.with(code: "mastro_insegnante_test", capabilities: [:read], delegatable_role_codes: [teacher.code])
    brand = Node.new(slug: "posturacorretta")

    assert trainer.delegates_to?(teacher, brand_node: brand)
    assert_not teacher.delegates_to?(trainer, brand_node: brand)
    assert_not trainer.delegates_to?(teacher, brand_node: Node.new(slug: "generaimpresa"))
    assert_not trainer.delegates_to?(teacher.with(enabled: false), brand_node: brand)
    assert_not trainer.delegates_to?(nil, brand_node: brand)
    assert_not RoleDefinitions::Registry.registered?(trainer.code)
  end

  test "current definitions do not authorize any role delegation" do
    RoleDefinitions::Registry.all.each do |source|
      assert_empty source.delegatable_role_codes
      assert_not RoleDefinitions::Registry.delegation_allowed?(
        from: source.code, to: "gestore_generaimpresa", brand_node: Node.new(slug: "generaimpresa")
      )
    end
  end

  test "assignment respects the node types declared by the definition" do
    definition = RoleDefinitions::Registry.fetch("insegnante_posturacorretta")
    assert_equal %w[professional project], definition.node_types
    assert RoleDefinitions::Registry.assignable_to?(definition.code,
      brand_node: Node.new(slug: "posturacorretta"), node: Node.new(node_type: :professional))
    assert_not RoleDefinitions::Registry.assignable_to?(definition.code,
      brand_node: Node.new(slug: "posturacorretta"), node: Profile.new)
  end
end
