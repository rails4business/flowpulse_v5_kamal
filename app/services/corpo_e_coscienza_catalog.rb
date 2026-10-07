class CorpoECoscienzaCatalog
  ROOT = Rails.root.join("config/data/brands/corpoecoscienza").freeze

  def self.load
    professionals = YAML.safe_load_file(ROOT.join("professionals/index.yml"), permitted_classes: [], aliases: false)
      .to_h.fetch("professionals", [])
      .select { |item| item.fetch("public", false) }
      .filter_map do |item|
        source = ROOT.join("professionals", item.fetch("source")).cleanpath
        next unless source.to_s.start_with?(ROOT.join("professionals").to_s) && source.file?

        item.merge("body" => source.read)
      end

    {
      site: YAML.safe_load_file(ROOT.join("site.yml"), permitted_classes: [], aliases: false) || {},
      method_markdown: ROOT.join("pages/metodo.md").read,
      founder_markdown: ROOT.join("pages/georges-courchinoux.md").read,
      training_markdown: ROOT.join("pages/formazione.md").read,
      privacy_markdown: ROOT.join("pages/privacy.md").read,
      professionals: professionals,
      professional_map_points: professionals.filter_map do |professional|
        latitude = Float(professional["latitude"], exception: false)
        longitude = Float(professional["longitude"], exception: false)
        next unless latitude && longitude

        professional.slice("name", "city").merge("latitude" => latitude, "longitude" => longitude)
      end
    }
  end
end
