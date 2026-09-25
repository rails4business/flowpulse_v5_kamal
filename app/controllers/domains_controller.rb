class DomainsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access
  before_action :set_domain

  def show
    I18n.with_locale(Current.domain&.locale || I18n.default_locale) do
      if Current.domain&.canonical_host.present? && current_domain_host != Current.domain.canonical_host
        return redirect_to_canonical_host
      end

      dispatch_domain_action
    end
  end

  private
    def set_domain
      Current.domain = current_domain
    end

    def redirect_to_canonical_host
      canonical_host = Current.domain&.canonical_host.to_s.strip
      return if canonical_host.blank?
      return if current_domain_host == canonical_host

      redirect_to(
        "#{request.protocol}#{canonical_host}#{request.fullpath}",
        status: :moved_permanently,
        allow_other_host: true
      )
    end

    def dispatch_domain_action
      if Current.domain&.site_key.present?
        render_editorial_site(Current.domain.site_key)
      elsif Current.domain&.target_controller.present?
        render_domain_target
      elsif Current.domain&.node.present? && render_public_node(Current.domain.node)
        # successfully rendered assigned node
      elsif Current.domain&.role_assignment.present? && (creator_node = Current.domain.role_assignment.nodes.roots.published_free.order(:position, :title).find { |node| public_node_visible?(node) }) && render_public_node(creator_node)
        # successfully rendered creator's home/first root node
      else
        prepare_flowpulse_landing
        render "landing/flowpulse"
      end
    end

    def render_public_node(node)
      if public_node_visible?(node)
        @node = node
        @children = public_node_accessible_children(@node)
        @breadcrumbs = [@node]
        @siblings = [@node]
        @parent_node = nil
        @previous_sibling = nil
        @next_sibling = nil
        @traveler_subscription_domain = Current.domain if Current.domain&.node_id == node.id
        @traveler_subscription = Current.user&.profile&.traveler_subscriptions&.active&.find_by(domain: @traveler_subscription_domain) if @traveler_subscription_domain.present?
        @node.build_content if @node.content.blank?
        render "nodes/show", layout: "public_node"
        true
      else
        false
      end
    end

    def render_domain_target
      target_controller = Current.domain.target_controller
      target_action = Current.domain.target_action

      if target_controller == "landing"
        prepare_landing_target(target_action)
        render "landing/#{target_action}"
      elsif target_controller == "brands/genera_impresa" && target_action == "index"
        @catalog = GeneraImpresaCatalog.load
        @site = @catalog.site
        @brands = @catalog.brands
        render "brands/genera_impresa/index"
      elsif target_controller == "brands/svuotamente" && target_action == "index"
        render "brands/svuotamente/index", layout: false
      elsif target_controller == "brands/impegno/home" && target_action == "index"
        redirect_to impegno_path
      elsif target_controller == "brands/posturacorretta" && target_action == "home"
        redirect_to posturacorretta_path
      elsif target_controller == "brands/percorso_integrato" && target_action == "index"
        data = PercorsoIntegratoCatalog.load
        @site = data.fetch("site")
        @principles = data.fetch("principles", [])
        @roles = data.fetch("roles", [])
        @steps = data.fetch("steps", [])
        render "brands/percorso_integrato/index"
      else
        render "#{target_controller}/#{target_action}"
      end
    end

    def prepare_landing_target(target_action)
      if target_action == "rails4b"
        prepare_rails4b_landing
        return
      end
      if target_action == "flowpulse"
        prepare_flowpulse_landing
        return
      end
      if target_action == "giardino_del_corpo"
        prepare_garden_landing
        return
      end
      return unless target_action == "posturacorretta"

      @home_data = YAML.safe_load_file(
        Rails.root.join("config/data/posturacorretta/home/home.yml"),
        permitted_classes: [],
        aliases: false
      ) || {}
      @audiences = YAML.safe_load_file(
        Rails.root.join("config/data/posturacorretta/shared/audiences.yml"),
        permitted_classes: [],
        aliases: false
      ) || {}
      @posturacorretta_taxonomies = PosturacorrettaTaxonomies.load
    end

    def prepare_rails4b_landing
      @rails4b = YAML.safe_load_file(
        Rails.root.join("config/data/rails4b/landing.yml"),
        permitted_classes: [],
        aliases: false
      ) || {}
      @rails4b_path = YAML.safe_load_file(
        Rails.root.join("config/data/rails4b/percorso.yml"),
        permitted_classes: [],
        aliases: false
      ) || {}
      content_catalog = YAML.safe_load_file(
        Rails.root.join("config/data/rails4b/contenuti/catalog.yml"),
        permitted_classes: [],
        aliases: false
      ) || {}
      contents_by_slug = content_catalog.fetch("items", []).index_by { |content| content.fetch("slug") }
      @rails4b_track = @rails4b_path.fetch("tracks").find { |track| track.fetch("slug") == params[:percorso] } || @rails4b_path.fetch("tracks").first
      @rails4b_track_steps = @rails4b_track.fetch("steps").map do |step|
        contents_by_slug.fetch(step.fetch("content_slug")).merge("number" => step.fetch("number"))
      end
    end

    def prepare_flowpulse_landing
    end

    def prepare_garden_landing
      @garden_events = DomainEventCatalog.for_project(
        "giardino-del-corpo",
        include_drafts: Current.user&.superadmin_user? || false
      ).select { |event| event["event_date"].blank? || event.fetch("event_date") >= Date.current }
       .sort_by { |event| [event["event_date"] || Date.new(9999, 12, 31), event.fetch("title", "")] }
      @garden_places = AcademyCurriculum.load.fetch("locations", {}).values.select do |place|
        Array(place["projects"]).include?("giardino-del-corpo")
      end
    end
end
