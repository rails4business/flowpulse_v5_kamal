require "test_helper"

class RoleAssignmentTest < ActiveSupport::TestCase
  setup do
    @ideatore_user = User.create!(email_address: "ideatore@example.com", password: "password123", password_confirmation: "password123")
    @ideatore_user.create_profile!(display_name: "Ideatore")
    @ideatore = RoleAssignment.create!(profile: @ideatore_user.profile, role: :ideatore)
  end

  test "only an ideatore can be a root role" do
    child = RoleAssignment.new(profile: @ideatore_user.profile, role: :creator)
    assert_not child.valid?
    assert_includes child.errors[:parent_id], "deve essere impostato per i ruoli children"

    child.parent = @ideatore
    assert child.valid?

    root_with_parent = RoleAssignment.new(profile: @ideatore_user.profile, role: :ideatore, parent: @ideatore)
    assert_not root_with_parent.valid?
  end

  test "creator digital and responsabile are activatable when assigned" do
    user = User.create!(email_address: "digital@example.com", password: "password123", password_confirmation: "password123", active_role: :digital)
    user.create_profile!(display_name: "Digital")
    RoleAssignment.create!(profile: user.profile, role: :digital, parent: @ideatore)

    assert user.active_role_attivabile?
    assert_equal "digital", user.safe_active_role
    assert user.digital_user?
  end

  test "membership is not a role and demo is not activatable" do
    user = User.create!(email_address: "member@example.com", password: "password123", password_confirmation: "password123")
    user.create_profile!(display_name: "Member")

    assert_equal ["traveler"], user.ruoli_attivabili
    assert_not user.can_activate_role?("demo")
  end

  test "operator is scoped to a brand and can have multiple configured functions" do
    brand = Node.create!(title: "Brand operatori", role_assignment: @ideatore, operator_roles: %w[insegnante segreteria])
    operator = User.create!(email_address: "operator@example.com", password: "password123", password_confirmation: "password123")
    operator.create_profile!(display_name: "Operatore")

    teacher = RoleAssignment.create!(profile: operator.profile, role: :operator, role_operator: "insegnante", context: brand, parent: @ideatore)
    secretary = RoleAssignment.create!(profile: operator.profile, role: :operator, role_operator: "segreteria", context: brand, parent: @ideatore)

    assert teacher.operator?
    assert_equal "insegnante", teacher.role_operator
    assert secretary.persisted?
  end

  test "operator function must be configured on its brand" do
    brand = Node.create!(title: "Brand ristretto", role_assignment: @ideatore, operator_roles: ["insegnante"])
    assignment = RoleAssignment.new(profile: @ideatore_user.profile, role: :operator, role_operator: "professionista", context: brand, parent: @ideatore)

    assert_not assignment.valid?
    assert_includes assignment.errors[:role_operator], "non è previsto per questo Brand"
  end
end
