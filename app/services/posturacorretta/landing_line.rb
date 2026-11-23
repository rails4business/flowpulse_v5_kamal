module Posturacorretta
  # Linea presentata nella home, letta dal catalogo metro_lines.yml.
  class LandingLine
    Station = Data.define(:slug, :title, :index)

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
        Station.new(slug: node.slug, title: node.title.delete_prefix("Lezione · ").split(/ [-·] /).first, index:)
      end
    end

    private

      attr_reader :line, :nodes
  end
end
