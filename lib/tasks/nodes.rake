namespace :nodes do
  desc "Validate config/nodes.yml and its database references without saving"
  task validate: :environment do
    result = NodeCatalog.from_config.import!(dry_run: true)
    puts "Valid Node catalog: #{result.nodes} nodes, #{result.profiles} primary profiles."
  end

  desc "Import config/nodes.yml into the database"
  task import: :environment do
    result = NodeCatalog.from_config.import!
    puts "Imported #{result.nodes} nodes and linked #{result.profiles} primary profiles."
  end

  desc "Print the configured Node tree"
  task tree: :environment do
    roots = Node.where(parent_id: nil).includes(:domains, :professional_owner_node).order(:title)

    print_node = lambda do |node, depth|
      labels = []
      labels << "professional" if node.professional?
      labels << "brand" if node.domains.any?
      labels << node.node_type unless node.node_type == "node"
      puts "#{'  ' * depth}#{node.title}#{labels.any? ? " [#{labels.join(', ')}]" : ''}"
      node.children.includes(:domains, :professional_owner_node).order(:position, :title).each do |child|
        print_node.call(child, depth + 1)
      end
    end

    roots.each { |root| print_node.call(root, 0) }
  end
end
