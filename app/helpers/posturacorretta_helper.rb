module PosturacorrettaHelper
  GUIDE_INDEX_PATH = Rails.root.join("config/data/posturacorretta/guide/indice.yml").freeze
  REVISION_PROJECTS = {
    "accademia" => "accademia-posturacorretta",
    "percorso" => "percorsi-personalizzati-linee-guida",
    "eventi" => "eventi-posturacorretta",
    "contenuti" => "produzione-contenuti-posturacorretta",
    "metodiche" => "organizzazione-metodiche",
    "libro" => "libro-il-corpo-un-mondo-da-scoprire",
    "progetti" => "piattaforma-flowpulse-rails4business"
  }.freeze

  def posturacorretta_revision_project
    return unless controller_name == "posturacorretta"

    REVISION_PROJECTS[action_name]
  end

  def posturacorretta_guide_section_path(section_id, destination: :index)
    section = posturacorretta_guide_sections.find { |candidate| candidate["id"] == section_id.to_s }
    return posturacorretta_guida_path unless section
    return posturacorretta_guida_path(sezione: section.fetch("id")) unless destination.to_sym == :first

    first_chapter = first_published_guide_item(section.fetch("items", []), section.fetch("status", "draft"))
    return posturacorretta_guida_path(sezione: section.fetch("id")) unless first_chapter

    posturacorretta_guida_path(sezione: section.fetch("id"), capitolo: first_chapter.fetch("slug"))
  end

  def posturacorretta_builder_route(route)
    match = route.to_s.match(/\Aguide:(index|first):([a-z0-9_-]+)\z/)
    return route unless match

    posturacorretta_guide_section_path(match[2], destination: match[1])
  end

  private

  def posturacorretta_guide_sections
    @posturacorretta_guide_sections ||= begin
      data = YAML.safe_load_file(GUIDE_INDEX_PATH, permitted_classes: [], aliases: false) || {}
      data.fetch("sections", [])
    end
  end

  def first_published_guide_item(items, inherited_status)
    items.each do |item|
      status = item.fetch("status", inherited_status)
      next unless status == "published"

      if item["type"] == "group"
        child = first_published_guide_item(item.fetch("children", []), status)
        return child if child
      elsif item["slug"].present?
        return item
      end
    end

    nil
  end
end
