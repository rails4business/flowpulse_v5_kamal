class PercorsoIntegratoCatalog
  DATA_PATH = Rails.root.join("config/data/percorso_integrato/site.yml").freeze
  EXAMPLE_SHEET_PATH = Rails.root.join("config/data/brands/percorso-integrato/scheda_esempio.yml").freeze

  def self.load
    YAML.safe_load_file(DATA_PATH, permitted_classes: [], aliases: false)
  end

  # Scheda di fantasia mostrata nella home: persona, richiesta, presa in carico, professionisti, sedute, autonomia.
  def self.example_sheet
    YAML.safe_load_file(EXAMPLE_SHEET_PATH, permitted_classes: [], aliases: false)
  end
end
