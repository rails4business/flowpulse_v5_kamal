namespace :posturacorretta do
  desc "Import the methodology catalog into canonical Nodes and NodeContents"
  task import_methodology_nodes: :environment do
    node_result = NodeCatalog.from_config.import!
    methodology_result = Posturacorretta::MethodologyNodeImporter.new.import!

    puts "Imported #{node_result.nodes} configured Nodes."
    puts "Migrated #{methodology_result.nodes} methodologies and #{methodology_result.contents} NodeContents."
  end
end
