class MetroCatalogExporter
  def self.lines_yaml
    definitions = MetroLine.includes(:domain, :start_node, :end_node).order(:slug).each_with_object({}) do |line, hash|
      hash[line.slug] = {
        "title" => line.title,
        "description" => line.description,
        "domain_hostname" => line.domain.display_hostname,
        "start_node_slug" => line.start_node.slug,
        "end_node_slug" => line.end_node.slug,
        "station_node_slugs" => line.ordered_nodes.map(&:slug),
        "status" => line.status,
        "settings" => line.settings.presence
      }.compact
    end
    environment_yaml("lines" => definitions)
  end

  def self.offers_yaml
    definitions = Offer.includes(:metro_line, :start_node, :end_node).order(:slug).each_with_object({}) do |offer, hash|
      hash[offer.slug] = {
        "title" => offer.title,
        "description" => offer.description,
        "line_slug" => offer.metro_line.slug,
        "start_node_slug" => offer.start_node.slug,
        "end_node_slug" => offer.end_node.slug,
        "included_offer_slugs" => offer.included_offer_slugs.presence,
        "previous_purchase_mode" => offer.previous_purchase_mode,
        "discount_percent" => offer.discount_percent,
        "status" => offer.status,
        "settings" => offer.settings.presence
      }.compact
    end
    environment_yaml("offers" => definitions)
  end

  def self.maps_yaml
    maps = MetroMap.includes(:domain).order(:id).each_with_object({}) do |metro_map, definitions|
      hostname = metro_map.domain.display_hostname
      definitions[hostname] = {
        "title" => metro_map.title,
        "status" => metro_map.status,
        "grid" => MetroMapCatalog.grid_for(hostname)
      }.compact
    end
    environment_yaml("maps" => maps)
  end

  # Riscrive i blocchi map_placements di config/nodes.yml con le coordinate indicate (di default quelle
  # salvate nel database), lasciando invariato il resto del file.
  def self.nodes_yaml(source = Rails.root.join("config/nodes.yml").read, placements_by_slug = database_placements)
    source.gsub(/^    ([a-z0-9][a-z0-9-]*):\n.*?(?=^    [a-z0-9][a-z0-9-]*:\n|^development:|\z)/m) do |entry|
      slug = Regexp.last_match(1)
      body = entry.sub(/^      map_placements:\n(?:^        .*\n)*/, "")
      placements = placements_by_slug[slug]
      next body if placements.blank?

      block = YAML.dump("map_placements" => placements.sort.to_h).delete_prefix("---\n").lines.map { |line| "      #{line}" }.join
      trailing = body[/\n*\z/]
      "#{body.delete_suffix(trailing)}\n#{block}#{trailing.delete_prefix("\n")}"
    end
  end

  def self.database_placements
    MetroMapPlacement.includes(:node, metro_map: :domain).each_with_object({}) do |placement, hash|
      (hash[placement.node.slug] ||= {})[placement.metro_map.domain.display_hostname] = {
        "x" => placement.x.round(2),
        "y" => placement.y.round(2),
        "collapsed" => placement.collapsed? ? true : nil
      }.compact
    end
  end

  def self.environment_yaml(default)
    { "default" => default, "development" => default, "test" => default, "production" => default }.to_yaml
  end

  private_class_method :environment_yaml
end
