namespace :domains do
  desc "Import domains from config/dedicated_domains.yml into the database"
  task import: :environment do
    Domain.import_from_config!
    puts "Imported #{Domain.count} domains."
  end

  desc "Export domains from the database to tmp/flowpulse_domains.yml"
  task export: :environment do
    path = Rails.root.join("tmp", "flowpulse_domains.yml")

    File.write(path, Domain.export_to_yaml)
    puts "Exported domains to #{path}."
  end
end
