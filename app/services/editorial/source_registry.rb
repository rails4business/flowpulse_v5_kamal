module Editorial
  class SourceRegistry
    Definition = Data.define(:directory, :extension, :structured)

    SOURCES = {
      "inline" => Definition.new(directory: nil, extension: nil, structured: true),
      "shared" => Definition.new(directory: "shared", extension: ".yml", structured: true),
      "track" => Definition.new(directory: "tracks", extension: ".yml", structured: true),
      "document" => Definition.new(directory: "documents", extension: ".md", structured: false)
    }.freeze

    class << self
      def fetch(type)
        SOURCES.fetch(type.to_s) { raise InvalidSourceError, "Sorgente non registrata: #{type}" }
      end

      def registered?(type)
        SOURCES.key?(type.to_s)
      end

      def keys
        SOURCES.keys
      end
    end
  end
end
