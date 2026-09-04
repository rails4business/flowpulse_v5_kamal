module Brands
  module Impegno
    class HomeController < ApplicationController
      layout "landing"
      allow_unauthenticated_access

      AREAS = %w[agenda user domain_roles places contacts].freeze
      VIEWS = {
        "agenda" => %w[agenda],
        "user" => %w[practices recurring],
        "places" => [],
        "contacts" => []
      }.freeze
      DOMAIN_ROLE_VIEWS = {
        "professional" => %w[requests offering exchange reports],
        "teacher" => %w[requests offering exchange reports]
      }.freeze
      DEFAULT_DOMAIN_ROLE_VIEWS = %w[requests workspace].freeze
      DOMAIN_ROLE_LABELS = {
        "professional" => "Professionista",
        "teacher" => "Insegnante",
        "tutor" => "Tutor",
        "segreteria_clienti" => "Segreteria clienti",
        "responsabile_location" => "Responsabile della sede",
        "segreteria_amministrativa" => "Segreteria amministrativa"
      }.freeze
      OFFERING_TABS = %w[services paths classes courses events].freeze
      EXPERIENCE_TABS = %w[habits paths classes courses events].freeze
      AGENDA_PERIODS = %w[upcoming past].freeze
      PROFESSIONAL_AGENDA_FILTERS = %w[all events booking_slots].freeze
      DOMAIN_BRANDS = {
        "1impegno.it" => "impegno",
        "posturacorretta.org" => "posturacorretta",
        "percorsointegrato.it" => "percorso_integrato",
        "generaimpresa.it" => "generaimpresa",
        "cantachetipassa.it" => "cantachetipassa"
      }.freeze

      def index
        return unless authenticated?
        return redirect_legacy_professional_area if params[:area] == "professional"

        @impegno_brand = params[:brand].presence_in(%w[impegno posturacorretta percorso_integrato generaimpresa cantachetipassa personale]) || "impegno"
        @impegno_domains = available_impegno_domains
        @impegno_domain_options = domain_options
        @impegno_default_domain = default_domain_for(@impegno_brand)
        @impegno_domain_roles = available_domain_roles(@impegno_default_domain)
        @impegno_domain_role_labels = DOMAIN_ROLE_LABELS
        @impegno_professional_access = Current.user.professional_user?
        requested_area = params[:area].presence_in(AREAS) || "agenda"
        @impegno_has_domain_roles = Current.user.superadmin_user?
        fallback_domain = @impegno_domains.find { |domain| available_domain_roles(domain).any? } || @impegno_domains.first
        if requested_area == "domain_roles" && @impegno_has_domain_roles && @impegno_domain_roles.empty? && fallback_domain
          @impegno_default_domain = fallback_domain
          @impegno_brand = brand_key_for(fallback_domain)
          @impegno_domain_roles = available_domain_roles(fallback_domain)
        end
        @impegno_role = params[:role].presence_in(@impegno_domain_roles) || @impegno_domain_roles.first
        @impegno_area = requested_area == "domain_roles" && !@impegno_has_domain_roles ? "user" : requested_area
        requested_view = params[:view] == "programs" ? "practices" : params[:view]
        @impegno_area = "agenda" if %w[user domain_roles].include?(@impegno_area) && requested_view == "agenda"
        available_views = views_for_area(@impegno_area)
        @impegno_view = requested_view.presence_in(available_views) || available_views.first
        @impegno_period = @impegno_view == "agenda" ? params[:period].presence_in(AGENDA_PERIODS) : nil
        @impegno_agenda_filter = @impegno_area == "agenda" && @impegno_professional_access ? params[:agenda_filter].presence_in(PROFESSIONAL_AGENDA_FILTERS) || "all" : nil
        @impegno_tab = if @impegno_area == "domain_roles" && @impegno_view == "offering"
          params[:tab].presence_in(OFFERING_TABS) || "services"
        elsif @impegno_area == "user" && @impegno_view == "practices"
          params[:tab].presence_in(EXPERIENCE_TABS) || "habits"
        else
          params[:tab].to_s.presence
        end
        @workspace_date = parse_workspace_date
        @workspace_src = workspace_src
      end

      private

        def redirect_legacy_professional_area
          redirect_params = request.query_parameters.except("area", "role").merge(area: "domain_roles")
          redirect_params[:brand] = params[:brand] if params[:brand].present?
          redirect_to impegno_path(redirect_params), status: :moved_permanently
        end

        def views_for_area(area)
          return DOMAIN_ROLE_VIEWS.fetch(@impegno_role, DEFAULT_DOMAIN_ROLE_VIEWS) if area == "domain_roles"

          VIEWS.fetch(area)
        end

        def available_domain_roles(domain)
          return [] if domain.blank?

          configured_roles = Array(domain.operational_roles) & RoleAssignment.roles.keys
          return configured_roles if Current.user.superadmin_user?

          assigned_roles = Current.user.profile.role_assignments.for_context(domain).where(role: configured_roles).pluck(:role)
          configured_roles & assigned_roles
        end

        def parse_workspace_date
          Date.iso8601(params[:date])
        rescue Date::Error, TypeError
          Date.current
        end

        def workspace_src
          return impegno_contacts_path(workspace: "1") if @impegno_area == "contacts"
          return impegno_places_path(workspace: "1") if @impegno_area == "places"
          return unless @impegno_area == "agenda" && @impegno_view == "agenda"

          options = {
            workspace: "1",
            date: params[:date].presence,
            period: @impegno_period,
            area: @impegno_area,
            agenda_filter: @impegno_agenda_filter,
            view_mode: params[:view_mode].presence,
            default_brand: @impegno_brand,
            return_to: request.fullpath
          }.compact
          impegno_agenda_path(options)
        end

        def available_impegno_domains
          if Current.user.superadmin_user?
            return collapse_domains_by_brand(Domain.active.where(primary: true).includes(:node).order(:hostname))
          end

          profile = Current.user.profile
          subscribed_domains = profile.traveler_subscriptions.active.includes(domain: :node).filter_map do |subscription|
            subscription.domain if subscription.domain.active?
          end
          standalone_domains = profile.domain_memberships.active.includes(domain: :node).filter_map do |membership|
            membership.domain if membership.standalone_domain? && membership.domain.active?
          end

          collapse_domains_by_brand(subscribed_domains + standalone_domains)
        end

        def domain_options
          @impegno_domains.filter_map do |domain|
            brand = brand_key_for(domain)
            next if brand.blank?

            [domain.site_title.presence || domain.hostname, brand]
          end.uniq { |_label, brand| brand }
        end

        def collapse_domains_by_brand(domains)
          domains.to_a.uniq do |domain|
            brand = brand_key_for(domain)
            brand.present? ? [:brand, brand] : (domain.node_id.present? ? [:node, domain.node_id] : [:hostname, domain.hostname.sub(/\Awww\./, "")])
          end
        end

        def brand_key_for(domain)
          configured_slug = domain.auth_slug.to_s.presence_in(%w[impegno posturacorretta percorso_integrato generaimpresa personale])
          configured_slug || DOMAIN_BRANDS[domain.hostname.sub(/\Awww\./, "")]
        end

        def default_domain_for(brand)
          @impegno_domains.find { |domain| brand_key_for(domain) == brand }
        end
    end
  end
end
