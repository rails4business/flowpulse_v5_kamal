require "application_system_test_case"

class FlowpulseNavigationTest < ApplicationSystemTestCase
  test "opens Flowpulse and its public project directory" do
    visit flowpulse_path

    assert_text "Flowpulse"
    click_link "Progetti", match: :first

    assert_current_path flowpulse_projects_path
    assert_text "PosturaCorretta"
    assert_text "Rails4Business"
  end
end
