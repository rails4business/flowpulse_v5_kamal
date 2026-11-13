module Posturacorretta
  # Linea e offerte presentate nella home, lette dal catalogo (metro_lines.yml e offers.yml).
  class LandingLine
    Station = Data.define(:slug, :title, :index)
    OfferCard = Data.define(:slug, :title, :description, :included_titles, :entry_slug, :from_title, :to_title, :coverage) do
      def available? = entry_slug.present?
    end

    def self.find(slug)
      line = MetroLine.published.find_by(slug:)
      line && new(line)
    rescue MetroLine::InvalidRoute
      nil
    end

    def initialize(line)
      @line = line
      @nodes = line.ordered_nodes
    end

    def title = line.title
    def description = line.description

    # La linea mostra sia corsi sia lezioni: la forma della stazione comunica la differenza.
    def stations
      @stations ||= nodes.each_with_index.map do |node, index|
        Station.new(slug: node.slug, title: node.title.split(/ [-·] /).first, index:)
      end
    end

    # Ogni offerta comprende le precedenti: si entra dalla prima stazione non compresa nelle offerte incluse.
    def offers
      slugs = nodes.map(&:slug)
      records = line.offers.where.not(status: "archived").includes(:start_node, :end_node).to_a
      by_slug = records.index_by(&:slug)
      records.sort_by { |offer| slugs.index(offer.end_node.slug).to_i }.map do |offer|
        included = by_slug.values_at(*offer.included_offer_slugs).compact
        start_index = slugs.index(offer.start_node.slug).to_i
        end_index = slugs.index(offer.end_node.slug).to_i
        first_new = included.map { |item| slugs.index(item.end_node.slug).to_i + 1 }.max || start_index
        OfferCard.new(
          slug: offer.slug,
          title: offer.title,
          description: offer.description,
          included_titles: included.map(&:title),
          entry_slug: (offer.status == "published" ? journey_entry_slug(slugs.drop(first_new)) : nil),
          from_title: station_at_or_before(start_index)&.title,
          to_title: station_at_or_before(end_index)&.title,
          coverage: ((end_index + 1).fdiv(slugs.size) * 100).round(1)
        )
      end
    end

    private

      attr_reader :line, :nodes

      def station_at_or_before(index)
        stations.reverse.find { |station| station.index <= index }
      end

      def journey_entry_slug(slugs)
        journey_slugs = HomeJourney::STATIONS.map { |station| station.fetch("slug") }
        slugs.find { |slug| journey_slugs.include?(slug) }
      end
  end
end
