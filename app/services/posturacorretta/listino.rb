module Posturacorretta
  # Listino della home, letto da config/data/posturacorretta/listino.yml.
  # Sezioni e voci con audience: superadmin restano nascoste agli altri visitatori.
  class Listino
    PATH = Rails.root.join("config/data/posturacorretta/listino.yml").freeze

    Section = Data.define(:slug, :title, :description, :style, :items) do
      def steps? = style == "steps"
      def priced? = items.any?(&:price)
    end
    Item = Data.define(:title, :detail, :price, :node_slug, :offer_slug)

    def self.sections(path = PATH, superadmin: false)
      visible = ->(entry) { superadmin || entry["audience"] != "superadmin" }

      YAML.safe_load_file(path, permitted_classes: [], aliases: false).fetch("sections").select(&visible).filter_map do |section|
        items = section.fetch("items").select(&visible).map do |item|
          Item.new(
            title: item.fetch("title"),
            detail: item["detail"],
            price: item["price"].presence,
            node_slug: item["node_slug"],
            offer_slug: item["offer_slug"]
          )
        end
        next if items.empty?

        Section.new(
          slug: section.fetch("slug"),
          title: section.fetch("title"),
          description: section["description"],
          style: section["style"],
          items:
        )
      end
    end
  end
end
