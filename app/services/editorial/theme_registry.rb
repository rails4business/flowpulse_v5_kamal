module Editorial
  class ThemeRegistry
    Definition = Data.define(:layout, :wrapper_class)

    THEMES = {
      "markpostura" => Definition.new(
        layout: "landing",
        wrapper_class: "editorial-theme-markpostura bg-white text-slate-950"
      )
    }.freeze

    class << self
      def fetch(key)
        THEMES.fetch(key.to_s) { raise UnknownThemeError, "Tema non registrato: #{key}" }
      end

      def registered?(key)
        THEMES.key?(key.to_s)
      end
    end
  end
end
