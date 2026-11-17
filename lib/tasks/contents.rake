namespace :contents do
  desc "Validate the canonical content YAML in config/data/brands without saving"
  task validate: :environment do
    result = ContentCatalog.new.import!(dry_run: true)
    puts "Catalogo contenuti valido: #{result.contents} contenuti (#{result.created} nuovi), #{result.publications} pubblicazioni."
    result.warnings.each { |warning| puts "Avviso: #{warning}" }
  end

  desc "Import the canonical content YAML in config/data/brands into the database (publication state untouched)"
  task import: :environment do
    result = ContentCatalog.new.import!
    puts "Importati #{result.contents} contenuti (#{result.created} nuovi), #{result.publications} pubblicazioni e #{result.contributions} nuovi contributi."
    result.warnings.each { |warning| puts "Avviso: #{warning}" }
  end
end
