module Posturacorretta
  # Listino della home, letto da config/data/posturacorretta/listino.yml.
  class Listino
    PATH = Rails.root.join("config/data/posturacorretta/listino.yml").freeze

    Section = Data.define(:slug, :title, :description, :items)
    Item = Data.define(:title, :detail, :price, :node_slug, :offer_slug)

    def self.sections(path = PATH)
      YAML.safe_load_file(path, permitted_classes: [], aliases: false).fetch("sections").map do |section|
        Section.new(
          slug: section.fetch("slug"),
          title: section.fetch("title"),
          description: section["description"],
          items: section.fetch("items").map do |item|
            Item.new(
              title: item.fetch("title"),
              detail: item["detail"],
              price: item["price"].presence,
              node_slug: item["node_slug"],
              offer_slug: item["offer_slug"]
            )
          end
        )
      end
    end
  end
end
