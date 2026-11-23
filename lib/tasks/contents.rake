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
    puts "Importati #{result.contents} contenuti (#{result.created} nuovi), #{result.publications} pubblicazioni, #{result.contributions} nuovi contributi e #{result.links} nuovi legami."
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

  desc "Write config/data/contents_published_on.yml from written_on and the git history (run locally)"
  task generate_published_on: :environment do
    dates = ContentPublishedOn.new.generate!
    puts "Date scritte per #{dates.size} contenuti (#{dates.values.min} → #{dates.values.max})."
  end

  desc "Publish the draft contents with the date in config/data/contents_published_on.yml (DRY_RUN=1 to preview)"
  task publish_backlog: :environment do
    dry_run = ENV["DRY_RUN"].present?
    result = ContentPublishedOn.new.publish!(dry_run:)
    puts "#{'[prova] ' if dry_run}Contenuti pubblicati: #{result.published}."
    result.missing.each { |key| puts "Senza data: #{key}" }
  end
end
