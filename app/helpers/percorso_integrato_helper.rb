module PercorsoIntegratoHelper
  def percorso_integrato_document_path(slug)
    percorso_integrato_guidelines_path(doc: slug, anchor: "doc-#{slug}")
  end

  # I documenti condividono la pagina: titoli e ancore devono avere un ambito proprio.
  def percorso_integrato_guideline_body(html, slug)
    fragment = Nokogiri::HTML.fragment(html.to_s)
    anchors = fragment.css("[id]").to_h { |element| [element["id"], "doc-#{slug}-#{element['id']}"] }
    fragment.css("[id]").each { |element| element["id"] = anchors.fetch(element["id"]) }
    fragment.css("a[href^='#']").each do |link|
      target = anchors[link["href"].delete_prefix("#")]
      link["href"] = "##{target}" if target
    end
    fragment.css("h1, h2, h3, h4, h5, h6").each do |heading|
      heading.name = "h#{[heading.name.delete_prefix('h').to_i + 3, 6].min}"
    end
    fragment.to_html.html_safe
  end
end
