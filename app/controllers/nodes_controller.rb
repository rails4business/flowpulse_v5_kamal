class NodesController < ApplicationController
  include PublicNodePresentation

  layout "public_node"
  allow_unauthenticated_access only: [:show, :domain_home, :domain_expression, :domain_node, :domain_journey]

  def domain_home
    if params[:area].blank? && params[:parte].to_s.in?(%w[corpo risorse])
      redirect_to posturacorretta_connessione_path(tab: params[:parte]), status: :moved_permanently
      return
    end

    if params[:area].blank? && params[:parte].present?
      redirect_to posturacorretta_espressione_path(request.query_parameters), status: :moved_permanently
      return
    end

    domain = Domain.find_for_path_slug(params[:path_slug])
    # Il percorso locale si comporta come la root del dominio configurato,
    # anche se la richiesta arriva da localhost.
    Current.domain = domain if domain.present?
    node = domain&.node

    if node.blank? || !public_node_visible?(node)
      redirect_hidden_node
      return
    end

    # This path is the local/path-based preview of a domain home. The real
    # canonical page lives on the configured hostname.
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    prepare_public_node(node, navigation_domain: domain, domain_root: true)
    @posturacorretta_landing = node.slug == "posturacorretta"
    @posturacorretta_overview = @posturacorretta_landing
    prepare_posturacorretta_home(node)
    render :show
  end

  def domain_expression
    if params[:parte] == "intro"
      redirect_to posturacorretta_path(area: "intro"), status: :moved_permanently
      return
    end

    domain = Domain.find_for_path_slug(params[:path_slug])
    Current.domain = domain if domain.present?
    node = domain&.node

    if node.blank? || node.slug != "posturacorretta" || !public_node_visible?(node)
      redirect_hidden_node
      return
    end

    response.set_header("X-Robots-Tag", "noindex, nofollow")
    prepare_public_node(node, navigation_domain: domain, domain_root: true)
    @posturacorretta_landing = true
    @posturacorretta_expression = true
    prepare_posturacorretta_home(node)
    render :show
  end

  def domain_journey
    if params[:tab] == "percorso"
      redirect_to posturacorretta_path(area: "intro"), status: :moved_permanently
      return
    end

    domain = Domain.find_for_path_slug(params[:path_slug])
    Current.domain = domain if domain.present?
    node = domain&.node

    if node.blank? || node.slug != "posturacorretta" || !public_node_visible?(node)
      redirect_hidden_node
      return
    end

    requested_node = node.self_and_descendants.find_by(slug: params[:tappa]) if params[:tappa].present?
    if requested_node&.view_type == "course"
      destination = if requested_node.show_content
        posturacorretta_course_path(corso: requested_node.show_content.slug)
      else
        posturacorretta_course_path(corso: requested_node.slug)
      end
      redirect_to destination, status: :moved_permanently
      return
    end

    response.set_header("X-Robots-Tag", "noindex, nofollow")
    prepare_public_node(node, navigation_domain: domain, domain_root: true)
    prepare_posturacorretta_home(node)
    render :show
  end

  def domain_node
    domain = Domain.find_for_path_slug(params[:path_slug])
    Current.domain = domain if domain.present?
    node = domain&.node&.self_and_descendants&.find_by(slug: params[:node_slug])

    if node.blank? || !public_node_visible?(node)
      redirect_hidden_node
      return
    end

    # Il percorso con prefisso Brand è l'URL pubblico canonico anche in locale.
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    prepare_public_node(node, navigation_domain: domain, domain_root: false)
    prepare_posturacorretta_consapevolezza(node)
    prepare_posturacorretta_connessione(node)
    prepare_posturacorretta_public_section(node)
    render :show
  end

  def show
    @node = Node.find_by(id: params[:id])
    if @node.blank? || !public_node_visible?(@node)
      redirect_hidden_node
      return
    end

    response.set_header("X-Robots-Tag", "noindex, nofollow") unless PublicDiscovery::AccessPolicy.new.public_node?(@node)

    if @node.slug == "apprendimento-2-connessione"
      redirect_to posturacorretta_consapevolezza_path(request.query_parameters), status: :moved_permanently
      return
    end

    if @node.slug == "dalla-posturacorretta-al-giardino-del-corpo"
      redirect_to posturacorretta_connessione_path(request.query_parameters), status: :moved_permanently
      return
    end

    posturacorretta_section_paths = {
      "partecipa-posturacorretta" => posturacorretta_partecipa_path,
      "servizi-posturacorretta" => posturacorretta_servizi_path,
      "about-posturacorretta" => posturacorretta_about_path
    }
    if posturacorretta_section_paths.key?(@node.slug)
      redirect_to posturacorretta_section_paths.fetch(@node.slug), status: :moved_permanently
      return
    end

    if (target_path = domain_target_redirect_path(@node))
      redirect_to target_path, status: :found
      return
    end

    if @node.bridge_node?
      target = @node.resolve_target
      if target != @node && public_node_visible?(target)
        redirect_to node_path(target), status: :found
      else
        redirect_hidden_node
      end
      return
    end

    prepare_public_node(@node)
    prepare_posturacorretta_consapevolezza(@node)
    prepare_posturacorretta_connessione(@node)
    prepare_posturacorretta_public_section(@node)
    @posturacorretta_landing = true if @current_host_domain_root && @node.slug == "posturacorretta"
  end

  def edit
    node = Node.find(params[:id])
    unless NodeCatalogEditor.enabled? && Current.user&.superadmin_user?
      redirect_to node_path(node), alert: "L’editor del catalogo non è disponibile o non hai i permessi necessari."
      return
    end

    redirect_to edit_creator_world_role_assignment_node_path(
      node.role_assignment,
      node,
      return_to: params[:return_to].presence || node_path(node)
    )
  end

  private

  def redirect_hidden_node
    redirect_to root_path, alert: "Questo nodo non è pubblico o non è accessibile."
  end

  def domain_target_redirect_path(node)
    domain = target_domain_for(node)
    return nil if domain.blank?

    url_for(
      controller: "/#{domain.target_controller}",
      action: domain.target_action,
      only_path: true
    )
  rescue ActionController::UrlGenerationError
    nil
  end

  def target_domain_for(node)
    domains = node.domains.active
      .where.not(target_controller: [nil, ""])
      .where.not(target_action: [nil, ""])

    current = current_domain
    if current.present? && current.node_id == node.id && domains.exists?(id: current.id)
      return current
    end

    domains.order(primary: :desc, hostname: :asc).first
  end
end
