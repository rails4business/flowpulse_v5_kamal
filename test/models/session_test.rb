require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email_address: "session-owner@example.com", password: "password123")
    @owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: @owner.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Session Brand", role_assignment: assignment)
    @domain = Domain.create!(hostname: "session-brand.example", node: @node, role_assignment: assignment)

    @user = User.create!(email_address: "session-user@example.com", password: "password123")
    @user.create_profile!(display_name: "User")
    @access = @user.profile.brand_accesses.create!(source_domain: @domain)
  end

  test "a session is valid for every hostname belonging to its brand" do
    session = @user.sessions.create!(brand_access: @access)
    alias_domain = Domain.create!(hostname: "www.session-brand.example", canonical_host: @domain.hostname)

    assert session.active?
    assert session.valid_for?(@domain)
    assert session.valid_for?(alias_domain)
  end

  test "a session rejects a brand access belonging to another user" do
    other_user = User.create!(email_address: "other-session-user@example.com", password: "password123")
    other_user.create_profile!(display_name: "Other")

    session = other_user.sessions.new(brand_access: @access)

    assert_not session.valid?
    assert_includes session.errors[:brand_access_id], "deve appartenere allo stesso utente della sessione"
  end
end
