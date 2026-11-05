class NodesController < ApplicationController
  include PublicNodePresentation

  layout "public_node"
  allow_unauthenticated_access only: [:show, :domain_home]

  def domain_home
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
    render :show
  end

  def show
    @node = Node.find_by(id: params[:id])
    if @node.blank? || !public_node_visible?(@node)
      redirect_hidden_node
      return
    end

    response.set_header("X-Robots-Tag", "noindex, nofollow") unless PublicDiscovery::AccessPolicy.new.public_node?(@node)

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
