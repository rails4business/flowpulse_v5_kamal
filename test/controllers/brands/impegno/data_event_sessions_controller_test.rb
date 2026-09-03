require "test_helper"

module Brands
  module Impegno
    class DataEventSessionsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = User.create!(email_address: "sessions-admin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
        @admin.create_profile!(display_name: "Sessions Admin", username: "sessions_admin")
        @user = User.create!(email_address: "sessions-user@example.com", password: "password123", password_confirmation: "password123")
        @user.create_profile!(display_name: "Sessions User", username: "sessions_user")
        @domain = Domain.create!(hostname: "sessions-admin.example", locale: "it", target_controller: "landing", target_action: "flowpulse", active: true, primary: true)
        @root = DataEvent.create!(title: "Evento", classification: "event", node_kind: "root", domain: @domain, created_by_profile: @admin.profile, responsible_profile: @admin.profile, status: "organizing", visibility: "private")
        @day = @root.children.create!(title: "Pomeriggio", classification: "event", node_kind: "day", domain: @domain, created_by_profile: @admin.profile, starts_at: at(14), ends_at: at(19), status: "proposed", visibility: "private")
      end

      test "superadmin creates and edits a fixed bookable session" do
        sign_in(@admin)

        assert_difference("@day.children.where(node_kind: 'session').count", 1) do
          post impegno_data_event_sessions_url(@root, @day), params: { data_event: { title: "Lezione", starts_at: local(15, 0), ends_at: local(16, 0), maximum_participants: 8, bookable: "1" } }
        end

        session = @day.children.find_by!(title: "Lezione")
        assert_redirected_to edit_impegno_data_event_day_url(@root, @day)
        assert_equal 8, session.maximum_participants
        assert session.bookable?
        assert_equal "session", session.booking_mode
        assert_equal "open", session.registration_status

        patch impegno_data_event_session_url(@root, @day, session), params: { data_event: { title: "Lezione aggiornata", starts_at: local(15, 30), ends_at: local(16, 30), maximum_participants: 10, bookable: "0" } }
        assert_redirected_to edit_impegno_data_event_day_url(@root, @day)
        session.reload
        assert_equal "Lezione aggiornata", session.title
        assert_equal 10, session.maximum_participants
        assert_not session.bookable?
        assert_equal "none", session.booking_mode
      end

      test "session outside its day window is rejected" do
        sign_in(@admin)

        assert_no_difference("@day.children.count") do
          post impegno_data_event_sessions_url(@root, @day), params: { data_event: { title: "Fuori fascia", starts_at: local(18, 30), ends_at: local(20, 0), bookable: "1" } }
        end

        assert_response :unprocessable_entity
        assert_includes response.body, "devono rientrare nella fascia giornaliera"
      end

      test "non superadmin cannot create sessions" do
        sign_in(@user)
        assert_no_difference("@day.children.count") do
          post impegno_data_event_sessions_url(@root, @day), params: { data_event: { title: "Non autorizzata", starts_at: local(15, 0), ends_at: local(16, 0), bookable: "1" } }
        end
        assert_response :not_found
      end

      private

        def at(hour)
          Time.zone.local(2026, 9, 21, hour)
        end

        def local(hour, minute)
          "2026-09-21T#{format('%02d', hour)}:#{format('%02d', minute)}"
        end

        def sign_in(user)
          post session_url, params: { email_address: user.email_address, password: "password123" }
        end
    end
  end
end
