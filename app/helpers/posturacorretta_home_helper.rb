module PosturacorrettaHomeHelper
  def posturacorretta_home_quick_links(taxonomies = @posturacorretta_taxonomies)
    taxonomies ||= PosturacorrettaTaxonomies.load

    taxonomies.fetch("home_links").map do |link|
      source = posturacorretta_home_link_source(link, taxonomies)

      {
        eyebrow: link.fetch("eyebrow"),
        title: link["title"].presence || source.fetch("title"),
        description: link["description"].presence || source.fetch("description"),
        cta: link.fetch("cta"),
        path: posturacorretta_home_link_path(link.fetch("route_key")),
        classes: source["classes"]
      }
    end
  end

  private

  def posturacorretta_home_link_source(link, taxonomies)
    source = link["source"]
    return link unless source.present?

    section = source.fetch("section")
    slug = source.fetch("slug")
    taxonomies.fetch(section).fetch(slug)
  end

  def posturacorretta_home_link_path(route_key)
    case route_key
    when "accademia" then posturacorretta_accademia_path
    when "percorso" then posturacorretta_percorso_path
    when "eventi" then posturacorretta_eventi_path
    when "filosofia" then posturacorretta_filosofia_path
    when "progetti" then posturacorretta_progetti_path
    else
      raise ArgumentError, "Route PosturaCorretta non gestita: #{route_key}"
    end
  end
end
