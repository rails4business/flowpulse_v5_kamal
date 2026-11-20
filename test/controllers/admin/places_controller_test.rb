require "test_helper"

module Admin
  class PlacesControllerTest < ActionDispatch::IntegrationTest
    setup do
      owner = User.create!(email_address: "places-owner@example.com", password: "password123", password_confirmation: "password123")
      role = RoleAssignment.create!(profile: owner.create_profile!(display_name: "Luoghi"), role: :ideatore)
      @brand = Node.create!(role_assignment: role, title: "Brand luoghi", slug: "brand-luoghi-admin", status: "published")
      @domain = Domain.create!(hostname: "luoghi-admin.test", node: @brand, role_assignment: role, active: true, primary: true)
      @card = Content.create!(node: @brand, key: "centro-luoghi-admin", slug: "centro-luoghi-admin", format: "centro", title: "Scheda del centro")
    end

    test "only a superadmin can manage places" do
      user = User.create!(email_address: "places-user@example.com", password: "password123", password_confirmation: "password123")
      sign_in(user)

      get flowpulse_places_path

      assert_redirected_to viaggiatori_url
    end

    test "a superadmin creates a place, links it to a domain with its content and closes it" do
      superadmin = User.create!(email_address: "places-superadmin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
      sign_in(superadmin)

      post flowpulse_places_path, params: { place: { name: "Sede di prova", slug: "sede-di-prova", city: "Calvisano", latitude: "45.37", longitude: "10.34", directions_url: "https://maps.example/sede" } }
      place = Place.find_by!(slug: "sede-di-prova")
      assert_redirected_to edit_flowpulse_place_path(place)
      assert_equal "https://maps.example/sede", place.directions_url

      post flowpulse_place_place_domains_path(place), params: { place_domain: { domain_id: @domain.id } }
      place_domain = place.place_domains.find_by!(domain: @domain)
      patch flowpulse_place_place_domain_path(place, place_domain), params: { place_domain: { content_id: @card.id } }
      assert_equal @card, place_domain.reload.content

      get edit_flowpulse_place_path(place)
      assert_response :success
      assert_select "option[selected][value='#{@card.id}']", text: "Scheda del centro"

      patch flowpulse_place_path(place), params: { place: { publication_status: "published", publication_visibility: "public" } }
      assert place.reload.published?
      assert place.published_at.present?

      patch flowpulse_place_path(place), params: { place: { status: "closed", closed_on: "2026-06-30" } }
      assert_not place.reload.open?

      get flowpulse_places_path(dominio: @domain.hostname)
      assert_response :success
      assert_select "td", text: /Chiuso/

      delete flowpulse_place_place_domain_path(place, place_domain)
      assert_empty place.reload.place_domains
    end

    private

      def sign_in(user)
        post session_url, params: { email_address: user.email_address, password: "password123" }
      end
  end
end
