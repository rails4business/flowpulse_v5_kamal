class PercorsoIntegratoCatalog
  DATA_PATH = Rails.root.join("config/data/percorso_integrato/site.yml").freeze

  def self.load
    YAML.safe_load_file(DATA_PATH, permitted_classes: [], aliases: false)
  end
end
