require "test_helper"

class BrandProcessTest < ActiveSupport::TestCase
  test "groups experiences without deleting them with the process" do
    user = User.create!(email_address: "brand-process@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!(display_name: "Brand Process")
    assignment = RoleAssignment.create!(profile: profile, role: :ideatore)
    brand = Node.create!(title: "Process Brand", slug: "process-brand", role_assignment: assignment)
    process_record = BrandProcess.create!(node: brand, created_by_user: user, title: "Produzione video", status: "active")
    experience = DataExperience.create!(created_by_user: user, brand_process: process_record, title: "Primo video")

    process_record.destroy!

    assert_nil experience.reload.brand_process
  end
end
