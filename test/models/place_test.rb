require "test_helper"

class PlaceTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "place-owner@example.com", password: "password123", password_confirmation: "password123")
    owner = RoleAssignment.create!(profile: user.create_profile!(display_name: "Luoghi"), role: :ideatore)
    @brand = Node.create!(title: "Brand", slug: "brand-luoghi", role_assignment: owner)
    @collection = Node.create!(title: "Centri", slug: "centri-luoghi", parent: @brand, role_assignment: owner)
    @other_brand = Node.create!(title: "Altro", slug: "altro-luoghi", role_assignment: owner)
    @domain = Domain.create!(hostname: "luoghi.example.test", node: @brand, locale: "it", target_controller: "home", target_action: "index")
    @other_domain = Domain.create!(hostname: "altro-luoghi.example.test", node: @other_brand, locale: "it", target_controller: "home", target_action: "index")
    @place = Place.create!(name: "Sede", slug: "sede-luoghi", city: "Calvisano", latitude: 45.37, longitude: 10.34)
  end

  test "a place can be shown in several domains, each with its own content" do
    card = Content.create!(node: @collection, key: "centro-luoghi", slug: "centro-luoghi", format: "centro", title: "Centro")

    @place.place_domains.create!(domain: @domain, content: card)
    @place.place_domains.create!(domain: @other_domain)

    assert_equal [ @domain, @other_domain ], @place.domains.to_a
    assert_equal card, @place.place_domains.find_by!(domain: @domain).content
    assert_includes @domain.places, @place
  end

  test "the content of a place in a domain must belong to that domain" do
    card = Content.create!(node: @other_brand, key: "centro-altrove", slug: "centro-altrove", format: "centro", title: "Altrove")

    place_domain = @place.place_domains.new(domain: @domain, content: card)

    assert_not place_domain.valid?
    assert_includes place_domain.errors[:content], "deve appartenere a un node del dominio"
  end

  test "a closed place stays but is not among the open ones" do
    @place.update!(status: "closed", closed_on: Date.new(2026, 6, 30))

    assert_not_includes Place.open, @place
    assert Place.exists?(@place.id)
    assert_not Place.new(name: "X", slug: "x", status: "sospeso").valid?
  end

  test "a new place is a private draft and gets its publication date when published" do
    assert_equal "draft", @place.publication_status
    assert_equal "private", @place.publication_visibility
    assert_not_includes Place.published_for_public, @place

    @place.update!(publication_status: "published", publication_visibility: "public")

    assert @place.published_at.present?
    assert_includes Place.published_for_public, @place
  end
end
