namespace :skill_products do
  desc "Validate the versioned Skill Product catalog without saving"
  task validate: :environment do
    username = ENV.fetch("OWNER", "markpostura")
    count = SkillProductSnapshot.for_owner(username).import!(dry_run: true)
    puts "Catalogo valido: #{count} prodotti per @#{username}."
  end

  desc "Import versioned Skill Products (upsert, without deletions)"
  task import: :environment do
    username = ENV.fetch("OWNER", "markpostura")
    count = SkillProductSnapshot.for_owner(username).import!
    puts "Importati o aggiornati #{count} prodotti per @#{username}."
  end

  desc "Export Skill Products and their repository-backed Markdown"
  task export: :environment do
    username = ENV.fetch("OWNER", "markpostura")
    snapshot = SkillProductSnapshot.for_owner(username)
    snapshot.export!
    puts "Esportati i prodotti di @#{username} in #{snapshot.path.relative_path_from(Rails.root)}."
  end

  desc "Print the current Skill Product catalog"
  task dump: :environment do
    username = ENV.fetch("OWNER", "markpostura")
    puts YAML.dump(SkillProductSnapshot.for_owner(username).document(include_bodies: true))
  end
end
