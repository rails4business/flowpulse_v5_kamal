module DashboardNavigation
  class Paths
    def initialize(context:, local: false)
      @context = context
      @local = local
    end

    def home
      return "/" if context.brand.nil? || context.brand.slug == "flowpulse"
      return "/" unless local

      slug = context.domain&.path_slug.presence || context.brand.slug
      slug = "corpo-e-coscienza" if slug == "corpoecoscienza"
      "/#{slug}"
    end

    def dashboard
      context.brand&.slug == "flowpulse" || context.brand.nil? ? platform : brand
    end

    def brand(suffix = "")
      prefix = local ? "/#{context.brand.slug}/admin" : "/admin"
      suffix.present? ? "#{prefix}/#{suffix}" : prefix
    end

    def platform(path = "/admin/dashboard")
      return "/flowpulse#{path}" if local && path.start_with?("/admin")
      return path if local
      return path if context.brand.nil? || context.brand.slug == "flowpulse"

      "https://flowpulse.net#{path}"
    end

    def route(name, **options)
      Rails.application.routes.url_helpers.public_send(name, **options)
    end

    private

      attr_reader :context, :local
  end
end
