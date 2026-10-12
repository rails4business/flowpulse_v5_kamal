require "test_helper"

class DomainAccessTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "domain-access@example.com", password: "password123", password_confirmation: "password123")
    @profile = user.create_profile!(display_name: "Domain Access")
    creator = User.create!(email_address: "domain-access-creator@example.com", password: "password123", password_confirmation: "password123")
    creator.create_profile!(display_name: "Creator")
    assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Domain Access Brand", role_assignment: assignment)
    @domain = Domain.create!(hostname: "domain-access.example", node: @node, role_assignment: assignment, locale: "it")
    @brand_access = BrandAccess.create!(profile: @profile, source_domain: @domain)
  end

  test "belongs to a brand access and can be reactivated" do
    access = DomainAccess.create!(profile: @profile, domain: @domain, brand_access: @brand_access)
    assert access.active?

    access.cancel!
    assert_not access.active?

    access.reactivate!
    assert access.active?
    assert_raises ActiveRecord::RecordInvalid do
      DomainAccess.create!(profile: @profile, domain: @domain, brand_access: @brand_access)
    end
  end

  test "accepts another language domain for the same brand" do
    english_domain = Domain.create!(
      hostname: "domain-access-en.example",
      node: @node,
      role_assignment: @domain.role_assignment,
      locale: "en"
    )

    access = DomainAccess.create!(profile: @profile, domain: english_domain, brand_access: @brand_access)

    assert_equal "en", access.domain.locale
    assert_equal @node, access.brand_access.brand_node
  end

  test "rejects a domain belonging to another brand" do
    other_node = Node.create!(title: "Other Brand", role_assignment: @domain.role_assignment)
    other_domain = Domain.create!(hostname: "other-brand.example", node: other_node, role_assignment: @domain.role_assignment, locale: "it")
    access = DomainAccess.new(profile: @profile, domain: other_domain, brand_access: @brand_access)

    assert_not access.valid?
    assert_includes access.errors[:domain_id], "deve presentare lo stesso nodo dell'accesso al brand"
  end
end
