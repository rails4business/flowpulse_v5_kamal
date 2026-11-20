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
    Rake::Task["contents:link_commitments"].invoke
  end

  desc "Link commitments that only have a content_key to their Content, as history (DRY_RUN=1 to preview)"
  task link_commitments: :environment do
    dry_run = ENV["DRY_RUN"].present?
    result = ContentCommitmentLinks.new.link!(dry_run:)
    puts "#{'[prova] ' if dry_run}Impegni collegati: #{result.linked}."
    result.missing.each { |missing| puts "Non trovato: #{missing}" }
  end
end
