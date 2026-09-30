namespace :brand_nodes do
  desc "Validate a Brand Node snapshot without saving"
  task validate: :environment do
    slug = ENV.fetch("BRAND")
    count = BrandNodeSnapshot.for_slug(slug).import!(dry_run: true)
    puts "Snapshot valido: #{count} nodi per #{slug}."
  end

  desc "Import a Brand Node snapshot into the database (upsert, without deletions)"
  task import: :environment do
    slug = ENV.fetch("BRAND")
    count = BrandNodeSnapshot.for_slug(slug).import!
    puts "Importati o aggiornati #{count} nodi per #{slug}."
  end

  desc "Export the current Brand Node tree to its repository snapshot"
  task export: :environment do
    slug = ENV.fetch("BRAND")
    snapshot = BrandNodeSnapshot.for_slug(slug)
    snapshot.export!
    puts "Esportati i nodi di #{slug} in #{snapshot.path.relative_path_from(Rails.root)}."
  end
end
