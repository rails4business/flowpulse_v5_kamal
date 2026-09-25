module PosturacorrettaMethodologiesHelper
  METHODOLOGY_CONTENT_ROOT = Rails.root.join("config/data/posturacorretta/metodiche")

  def methodology_markdown(content_path)
    full_path = METHODOLOGY_CONTENT_ROOT.join(content_path.to_s).cleanpath
    return "".html_safe unless full_path.to_s.start_with?(METHODOLOGY_CONTENT_ROOT.to_s)
    return "".html_safe unless full_path.file?

    markdown(full_path.read)
  end

  def methodology_professionals_for(professionals, methodology_slug)
    professionals.select { |professional| professional.fetch("methodologies", []).include?(methodology_slug) }
  end

  def methodology_schools_for(schools, methodology_slug)
    schools.to_a.select { |school| school.fetch("methodologies", []).include?(methodology_slug) }
  end

  def methodology_badge_classes(badge)
    methodology_audience(badge).fetch("classes", "border-slate-200 bg-slate-50 text-slate-700")
  end

  def methodology_badge_label(badge)
    methodology_audience(badge).fetch("label", badge.to_s)
  end

  def methodology_website_host(website_url)
    website_url.to_s.sub(%r{\Ahttps?://}, "").sub(%r{/.*\z}, "")
  end

  private

  def methodology_audience(badge)
    @posturacorretta_taxonomies ||= PosturacorrettaTaxonomies.load
    @posturacorretta_taxonomies.fetch("audiences", {}).fetch(badge.to_s, {})
  end
end
