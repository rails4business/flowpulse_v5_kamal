require "test_helper"

module Brands
  module Impegno
    class ContactsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email_address: "contacts@example.com", password: "password123", password_confirmation: "password123")
        @user.create_profile!(display_name: "Contacts User", username: "contacts_user")
        post session_url, params: { email_address: @user.email_address, password: "password123" }
      end

      test "lists and creates only the current profile contacts" do
        other_user = User.create!(email_address: "other-contacts@example.com", password: "password123", password_confirmation: "password123")
        other_user.create_profile!(display_name: "Other User", username: "other_contacts_user")
        Brands::Impegno::Contact.create!(profile: other_user.profile, name: "Contatto altrui")

        get impegno_contacts_url(workspace: "1")

        assert_response :success
        assert_select "turbo-frame#impegno_workspace"
        assert_select "body", text: /Contatti/
        assert_select "body", text: /Contatto altrui/, count: 0

        post impegno_contacts_url, params: { impegno_contact: { name: "Centro Salute", kind: "organization", email: "info@centrosalute.test", phone: "0301234567" } }

        assert_redirected_to impegno_path(area: "contacts")
        contact = @user.profile.impegno_contacts.find_by!(name: "Centro Salute")
        assert_equal "organization", contact.kind
      end
    end
  end
end
