namespace :deploy do
  desc "Synchronize versioned Nodes, Skills, optional Skill Products and Domains"
  task sync_catalogs: :environment do
    username = ENV.fetch("OWNER", "markpostura")

    node_result = NodeCatalog.from_config.import!
    puts "Imported #{node_result.nodes} nodes and linked #{node_result.profiles} primary profiles."

    skill_count = ReusableSkillSnapshot.for_owner(username).import!
    puts "Importate o aggiornate #{skill_count} Skill per @#{username}."

    product_snapshot = SkillProductSnapshot.for_owner(username)
    if product_snapshot.path.file?
      product_count = product_snapshot.import!
      puts "Importati o aggiornati #{product_count} prodotti per @#{username}."
    else
      puts "Catalogo Skill Product non presente: import saltato."
    end

    Domain.import_from_config!
    puts "Imported #{Domain.count} domains."
  end
end
