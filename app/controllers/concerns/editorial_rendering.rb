module EditorialRendering
  extend ActiveSupport::Concern

  private

  def render_editorial_site(site_key, path: "/", preview: false)
    context = Editorial::PageResolver.new.resolve(site_key, path: path, preview: preview)
    @editorial_site = context.site
    @editorial_mount = context.mount
    @editorial_page_config = context.page_configuration
    @editorial_page = context.page
    @editorial_theme = context.theme

    response.headers["X-Robots-Tag"] = "noindex, nofollow" if preview || @editorial_page["visibility"] != "public"
    render "editorial/show", layout: @editorial_theme.layout
  end
end
