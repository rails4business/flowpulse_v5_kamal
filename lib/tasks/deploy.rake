namespace :deploy do
  desc "Synchronize versioned Nodes, Skills, optional Skill Products and Domains"
  task sync_catalogs: :environment do
    username = ENV.fetch("OWNER", "markpostura")

    node_catalog = NodeCatalog.from_config
    node_result = node_catalog.import!(remove_configured: false)
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

    commercial = LineOfferCatalog.from_config.import!
    maps = MetroMapCatalog.from_config.import!
    puts "Importate #{commercial.lines} linee, #{commercial.offers} offerte, #{maps.maps} mappe e #{maps.placements} posizioni."
    puts "Rimossi #{node_catalog.remove_configured!} Node obsoleti."
  end
end
