namespace :skills do
  desc "Validate the versioned Skill catalog without saving"
  task validate: :environment do
    username = ENV.fetch("OWNER", "markpostura")
    count = ReusableSkillSnapshot.for_owner(username).import!(dry_run: true)
    puts "Catalogo valido: #{count} Skill per @#{username}."
  end

  desc "Import the versioned Skill catalog (upsert, without deletions)"
  task import: :environment do
    username = ENV.fetch("OWNER", "markpostura")
    count = ReusableSkillSnapshot.for_owner(username).import!
    puts "Importate o aggiornate #{count} Skill per @#{username}."
  end

  desc "Export the owner's current Skills to the repository catalog"
  task export: :environment do
    username = ENV.fetch("OWNER", "markpostura")
    snapshot = ReusableSkillSnapshot.for_owner(username)
    snapshot.export!
    puts "Esportate le Skill di @#{username} in #{snapshot.path.relative_path_from(Rails.root)}."
  end

  desc "Print the owner's current Skill catalog to standard output"
  task dump: :environment do
    username = ENV.fetch("OWNER", "markpostura")
    snapshot = ReusableSkillSnapshot.for_owner(username)
    puts YAML.dump(snapshot.document)
  end
end
