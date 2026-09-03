require "test_helper"

module Brands
  module Impegno
    class DataEventDaysControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = User.create!(email_address: "days-admin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
        @admin.create_profile!(display_name: "Days Admin", username: "days_admin")
        @user = User.create!(email_address: "days-user@example.com", password: "password123", password_confirmation: "password123")
        @user.create_profile!(display_name: "Days User", username: "days_user")
        @domain = Domain.create!(hostname: "days-admin.example", locale: "it", target_controller: "landing", target_action: "flowpulse", active: true, primary: true)
        @root = DataEvent.create!(title: "Evento con fasce", classification: "event", node_kind: "root", domain: @domain, created_by_profile: @admin.profile, responsible_profile: @admin.profile, status: "organizing", visibility: "private")
      end

      test "superadmin creates multiple non overlapping bookable windows on the same date" do
        sign_in(@admin)

        assert_difference("@root.children.where(node_kind: 'day').count", 2) do
          create_day("Mattina", "2026-09-14T09:00", "2026-09-14T12:00", true)
          assert_redirected_to edit_impegno_data_event_url(@root)
          create_day("Pomeriggio", "2026-09-14T15:00", "2026-09-14T18:00", true)
        end

        morning = @root.children.find_by!(title: "Mattina")
        assert_equal @root.domain, morning.domain
        assert_equal @root.classification, morning.classification
        assert_equal "day", morning.node_kind
        assert_equal "individual_request", morning.booking_mode
        assert_equal "required", morning.registration_mode
        assert_equal "open", morning.registration_status
        assert morning.bookable?
      end

      test "overlapping window is rejected and displayed in the form" do
        @root.children.create!(title: "Mattina", classification: "event", node_kind: "day", domain: @domain, created_by_profile: @admin.profile, starts_at: Time.zone.parse("2026-09-14 09:00"), ends_at: Time.zone.parse("2026-09-14 12:00"), status: "proposed", visibility: "private")
        sign_in(@admin)

        assert_no_difference("@root.children.count") do
          create_day("Sovrapposta", "2026-09-14T11:00", "2026-09-14T13:00", false)
        end

        assert_response :unprocessable_entity
        assert_select "p", text: "Controlla la fascia inserita"
        assert_includes response.body, "si sovrappone a un&#39;altra fascia"
      end

      test "superadmin edits a window and can disable booking" do
        day = @root.children.create!(title: "Sera", classification: "event", node_kind: "day", domain: @domain, created_by_profile: @admin.profile, starts_at: Time.zone.parse("2026-09-14 19:00"), ends_at: Time.zone.parse("2026-09-14 21:00"), status: "proposed", visibility: "private", bookable: true, booking_mode: "individual_request", registration_mode: "required", registration_status: "open")
        sign_in(@admin)

        patch impegno_data_event_day_url(@root, day), params: { data_event: { title: "Prima serata", starts_at: "2026-09-14T18:30", ends_at: "2026-09-14T20:30", bookable: "0" } }

        assert_redirected_to edit_impegno_data_event_url(@root)
        day.reload
        assert_equal "Prima serata", day.title
        assert_not day.bookable?
        assert_equal "none", day.booking_mode
        assert_equal "none", day.registration_mode
        assert_equal "pending", day.registration_status
      end

      test "non superadmin cannot manage windows" do
        sign_in(@user)

        get new_impegno_data_event_day_url(@root)
        assert_response :not_found
        assert_no_difference("@root.children.count") do
          create_day("Non autorizzata", "2026-09-14T09:00", "2026-09-14T10:00", true)
        end
        assert_response :not_found
      end

      private

        def create_day(title, starts_at, ends_at, bookable)
          post impegno_data_event_days_url(@root), params: { data_event: { title:, starts_at:, ends_at:, bookable: bookable ? "1" : "0" } }
        end

        def sign_in(user)
          post session_url, params: { email_address: user.email_address, password: "password123" }
        end
    end
  end
end
