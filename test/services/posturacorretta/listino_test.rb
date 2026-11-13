require "test_helper"

module Posturacorretta
  class ListinoTest < ActiveSupport::TestCase
    test "reads the home price list sections and items" do
      sections = Listino.sections

      assert_equal %w[lezioni-e-percorsi avanzati servizi-personalizzati], sections.map(&:slug)
      first = sections.first.items.second
      assert_equal "La prima settimana con PosturaCorretta", first.title
      assert_equal "prima-settimana-posturacorretta", first.offer_slug
      assert_nil first.price
    end

    test "links only to nodes declared in the catalog" do
      catalog = Rails.application.config_for(:nodes, env: "test").to_h.deep_stringify_keys.fetch("nodes").keys
      linked = Listino.sections.flat_map(&:items).filter_map(&:node_slug)

      assert_empty linked - catalog
    end
  end
end
