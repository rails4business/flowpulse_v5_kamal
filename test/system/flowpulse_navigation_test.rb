require "application_system_test_case"

class FlowpulseNavigationTest < ApplicationSystemTestCase
  test "opens Flowpulse and its unified public network directory" do
    visit flowpulse_path

    assert_text "Flowpulse"
    click_link "Rete", match: :first

    assert_current_path flowpulse_global_network_path
    assert_text "Brand"
  end
end
