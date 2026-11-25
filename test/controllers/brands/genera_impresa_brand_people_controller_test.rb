require "test_helper"

class Brands::GeneraImpresaBrandPeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "brand-people-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(
      title: "GeneraImpresa",
      slug: "generaimpresa",
      role_assignment: @root_assignment,
      operator_roles: %w[gestore_generaimpresa imprenditore_generaimpresa]
    )
    @domain = Domain.create!(hostname: "brand-people.example", node: @brand, role_assignment: @root_assignment, locale: "it")
    @manager = User.create!(email_address: "brand-people-manager@example.com", password: "password123")
    manager_profile = @manager.create_profile!(display_name: "Manager")
    manager_access = BrandAccess.create!(profile: manager_profile, source_domain: @domain)
    manager_assignment = RoleAssignment.create!(
      profile: manager_profile,
      role: :operator,
      role_operator: "gestore_generaimpresa",
      context: @brand,
      parent: @root_assignment,
      brand_access: manager_access
    )
    manager_access.select_role_assignment!(manager_assignment)
    @person = User.create!(email_address: "brand-person@example.com", password: "password123")
    @person_profile = @person.create_profile!(display_name: "Brand Person")
    @person_access = BrandAccess.create!(profile: @person_profile, source_domain: @domain)
    host! @domain.hostname
  end

  test "manager sees only GeneraImpresa profiles and accesses" do
    other_owner = User.create!(email_address: "other-brand-owner@example.com", password: "password123")
    other_owner.create_profile!(display_name: "Other owner")
    other_assignment = RoleAssignment.create!(profile: other_owner.profile, role: :ideatore)
    other_brand = Node.create!(title: "Other brand", slug: "other-brand-people", role_assignment: other_assignment)
    other_domain = Domain.create!(hostname: "other-brand-people.example", node: other_brand, role_assignment: other_assignment, locale: "it")
    outsider = User.create!(email_address: "outsider-brand@example.com", password: "password123")
    outsider_profile = outsider.create_profile!(display_name: "Outsider")
    BrandAccess.create!(profile: outsider_profile, source_domain: other_domain)
    sign_in(@manager)

    get genera_impresa_people_url

    assert_response :success
    assert_select "[data-brand-access-id='#{@person_access.id}']", text: /Brand Person/
    assert_select "body", text: /Outsider/, count: 0
    assert_select "a[href='#{admin_profile_path(@person_profile)}']", count: 0
  end

  test "manager revokes a GeneraImpresa access" do
    sign_in(@manager)

    delete genera_impresa_person_url(@person_access)

    assert_redirected_to genera_impresa_people_path
    assert_equal "cancelled", @person_access.reload.status
  end

  test "entrepreneur cannot open the Brand people index" do
    entrepreneur = User.create!(email_address: "brand-people-entrepreneur@example.com", password: "password123")
    profile = entrepreneur.create_profile!(display_name: "Entrepreneur")
    access = BrandAccess.create!(profile:, source_domain: @domain)
    assignment = RoleAssignment.create!(
      profile:,
      role: :operator,
      role_operator: "imprenditore_generaimpresa",
      context: @brand,
      parent: @root_assignment,
      brand_access: access
    )
    access.select_role_assignment!(assignment)
    sign_in(entrepreneur)

    get genera_impresa_people_url

    assert_response :forbidden
  end

  test "superadmin sees the link to the global profile" do
    superadmin = User.create!(email_address: "brand-people-superadmin@example.com", password: "password123", superadmin: true)
    sign_in(superadmin)

    get genera_impresa_people_url

    assert_response :success
    assert_select "a[href='#{admin_profile_path(@person_profile)}']", text: "Scheda globale"
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
