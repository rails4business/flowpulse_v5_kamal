module SeoHelper
  FILTERED_LISTING_PATHS = %w[
    /posturacorretta/contenuti
    /posturacorretta/metodiche
  ].freeze

  def seo_filtered_listing?
    meaningful_query_parameters = request.query_parameters.except("tab")
    request.get? && meaningful_query_parameters.present? && FILTERED_LISTING_PATHS.include?(request.path)
  end

  def seo_canonical_url
    domain = Current.domain || current_domain
    base_url = domain.present? ? "https://#{domain.hostname}" : request.base_url

    "#{base_url}#{request.path}"
  end

  def seo_noindex?
    return true if seo_filtered_listing?
    return true if @node.present? && !PublicDiscovery::AccessPolicy.new.public_node?(@node)

    false
  end

  def seo_json_ld(domain:, title:, description:, url:, node: nil, resource: nil, breadcrumbs: [])
    base_url = domain.present? ? "https://#{domain.hostname}" : request.base_url
    projection = PublicDiscovery::Projection.new(domain).call if domain.present?
    projected_domain = projection&.fetch("domain", {}) || {}
    projected_root = projection&.fetch("root_node", {}) || {}
    identity_type = projected_root["node_type"] == "professional" ? "Person" : "Organization"
    identity_name = projected_root["title"].presence || projected_domain["title"].presence || title
    identity_description = projected_root["description"].presence || projected_domain["description"].presence || description
    identity_id = "#{base_url}/#identity"
    website_id = "#{base_url}/#website"

    identity = {
      "@type" => identity_type,
      "@id" => identity_id,
      "name" => identity_name,
      "url" => "#{base_url}/",
      "description" => identity_description
    }.compact
    logo = projected_domain["logo_url"].presence || domain&.logo_full_url.presence || domain&.logo_square_url.presence
    identity["logo"] = logo if logo.present? && identity_type == "Organization"
    identity["image"] = logo if logo.present? && identity_type == "Person"

    graph = [identity,
      {
        "@type" => "WebSite",
        "@id" => website_id,
        "url" => "#{base_url}/",
        "name" => domain&.site_title.presence || title,
        "description" => domain&.site_description.presence || description,
        "inLanguage" => domain&.locale.presence || I18n.locale.to_s,
        "publisher" => { "@id" => identity_id }
      }.compact,
      {
        "@type" => "WebPage",
        "@id" => "#{url}#webpage",
        "url" => url,
        "name" => title,
        "description" => description,
        "isPartOf" => { "@id" => website_id },
        "about" => { "@id" => identity_id },
        "inLanguage" => domain&.locale.presence || I18n.locale.to_s
      }.compact
    ]

    if node.present? && projected_root["id"] != node.id
      projected_node = Array(projection&.fetch("nodes", [])).find { |item| item["id"] == node.id }
      node_entity_id = "#{projected_node&.fetch('url', url) || url}#node"
      graph << {
        "@type" => node.node_type == "professional" ? "Person" : "Thing",
        "@id" => node_entity_id,
        "name" => node.title,
        "description" => node.description.presence,
        "url" => projected_node&.fetch("url", url) || url,
        "isPartOf" => { "@id" => identity_id }
      }.compact
      graph.find { |item| item["@type"] == "WebPage" }["about"] = { "@id" => node_entity_id }
    end

    if resource.present?
      resource_entity_id = "#{url}#resource"
      resource_type = schema_type_for_resource(resource)
      graph << {
        "@type" => resource_type,
        "@id" => resource_entity_id,
        "name" => resource.title,
        "description" => description,
        "url" => url,
        "inLanguage" => resource.data.to_h["locale"].presence || domain&.locale.presence || I18n.locale.to_s,
        "datePublished" => resource.published_at&.iso8601,
        "dateModified" => resource.updated_at&.iso8601,
        "publisher" => { "@id" => identity_id },
        "isPartOf" => { "@id" => website_id }
      }.compact
      webpage = graph.find { |item| item["@type"] == "WebPage" }
      webpage["mainEntity"] = { "@id" => resource_entity_id }
    end

    breadcrumb_items = Array(breadcrumbs).each_with_index.map do |breadcrumb, index|
      projected_node = if projected_root["id"] == breadcrumb.id
        projected_root
      else
        Array(projection&.fetch("nodes", [])).find { |item| item["id"] == breadcrumb.id }
      end
      breadcrumb_url = projected_node&.fetch("url", nil) || "#{base_url}#{node_path(breadcrumb.resolve_target)}"
      {
        "@type" => "ListItem",
        "position" => index + 1,
        "name" => breadcrumb.title,
        "item" => breadcrumb_url
      }
    end
    if breadcrumb_items.any?
      graph << {
        "@type" => "BreadcrumbList",
        "@id" => "#{url}#breadcrumb",
        "itemListElement" => breadcrumb_items
      }
    end

    JSON.generate("@context" => "https://schema.org", "@graph" => graph)
  end

  private

    def schema_type_for_resource(resource)
      requested = resource.data.to_h["schema_type"].to_s
      return requested if requested.in?(%w[Article Course Event Service Place HowTo CreativeWork])

      case resource.data.to_h["content_type"].to_s
      when "article" then "Article"
      when "course" then "Course"
      when "event" then "Event"
      when "service" then "Service"
      when "place" then "Place"
      else "CreativeWork"
      end
    end
end
