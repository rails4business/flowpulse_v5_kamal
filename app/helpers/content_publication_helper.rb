module ContentPublicationHelper
  def content_publication_embed(publication)
    return if publication.blank?

    source = publication_embed_source(publication)
    return link_to("Apri #{publication.platform.humanize}", publication.url, target: "_blank", rel: "noopener", class: "font-bold text-blue-700 hover:underline") unless source

    tag.div(class: "privacy-embed aspect-video overflow-hidden rounded-2xl bg-slate-100", data: { controller: "privacy-embed" }) do
      safe_join([
        tag.iframe(
          "",
          title: publication.title.presence || "Video #{publication.platform.humanize}",
          frameborder: 0,
          allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",
          referrerpolicy: "strict-origin-when-cross-origin",
          allowfullscreen: true,
          hidden: true,
          class: "h-full w-full",
          data: { privacy_content: "functionality", privacy_category: "functionality", privacy_embed_src: source }
        ),
        tag.div(class: "privacy-embed__placeholder", data: { privacy_placeholder: "functionality" }) do
          safe_join([
            tag.strong("Video #{publication.platform.humanize}"),
            tag.p("Il video viene caricato soltanto dopo la tua scelta."),
            tag.button("Carica il video", type: "button", data: { privacy_enable: "functionality" })
          ])
        end
      ])
    end
  end

  private

    def publication_embed_source(publication)
      identifier = publication.external_id.presence || publication_identifier(publication.platform, publication.url)
      return if identifier.blank?

      case publication.platform
      when "youtube" then "https://www.youtube-nocookie.com/embed/#{ERB::Util.url_encode(identifier)}"
      when "vimeo" then "https://player.vimeo.com/video/#{ERB::Util.url_encode(identifier)}"
      end
    end

    def publication_identifier(platform, url)
      uri = URI.parse(url.to_s)
      case platform
      when "youtube"
        return uri.path.delete_prefix("/") if uri.host&.include?("youtu.be")
        Rack::Utils.parse_query(uri.query.to_s)["v"] || uri.path[%r{/embed/([^/?]+)}, 1]
      when "vimeo"
        uri.path[%r{/video/(\d+)}, 1] || uri.path[%r{/(\d+)}, 1]
      end
    rescue URI::InvalidURIError
      nil
    end
end
