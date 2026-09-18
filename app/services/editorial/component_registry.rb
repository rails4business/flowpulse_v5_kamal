module Editorial
  class ComponentRegistry
    Definition = Data.define(:partial, :variants, :required_data, :items)

    DEFINITIONS = {
      "hero" => Definition.new(
        partial: "editorial/components/hero",
        variants: %w[default split compact],
        required_data: %w[title description],
        items: false
      ),
      "section_header" => Definition.new(
        partial: "editorial/components/section_header",
        variants: %w[default compact],
        required_data: %w[title],
        items: false
      ),
      "text" => Definition.new(
        partial: "editorial/components/text",
        variants: %w[default lead centered],
        required_data: %w[body],
        items: false
      ),
      "timeline_embed" => Definition.new(
        partial: "editorial/components/timeline_embed",
        variants: %w[default],
        required_data: %w[source],
        items: false
      ),
      "three_languages" => Definition.new(
        partial: "editorial/components/three_languages",
        variants: %w[default],
        required_data: [],
        items: true
      ),
      "image" => Definition.new(
        partial: "editorial/components/image",
        variants: %w[default portrait cover],
        required_data: %w[url alt],
        items: false
      ),
      "card" => Definition.new(
        partial: "editorial/components/card",
        variants: %w[default compact],
        required_data: %w[title],
        items: false
      ),
      "feature_grid" => Definition.new(
        partial: "editorial/components/feature_grid",
        variants: %w[default projects hierarchy],
        required_data: [],
        items: true
      ),
      "steps" => Definition.new(
        partial: "editorial/components/steps",
        variants: %w[default horizontal],
        required_data: [],
        items: true
      ),
      "call_to_action" => Definition.new(
        partial: "editorial/components/call_to_action",
        variants: %w[default accent contact],
        required_data: %w[title description],
        items: false
      )
    }.freeze

    class << self
      def fetch(type)
        DEFINITIONS.fetch(type.to_s) { raise UnknownComponentError, "Componente non registrato: #{type}" }
      end

      def registered?(type)
        DEFINITIONS.key?(type.to_s)
      end

      def keys
        DEFINITIONS.keys
      end
    end
  end
end
