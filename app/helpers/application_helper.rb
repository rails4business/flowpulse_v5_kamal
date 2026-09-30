module ApplicationHelper
  # Keeps ImageKit transformations in one place. URLs that are not served by
  # ImageKit are left untouched, so the helper is safe for editorial content.
  def imagekit_url(source, width:, quality: 80)
    return source unless source.to_s.start_with?("https://ik.imagekit.io/")

    separator = source.include?("?") ? "&" : "?"
    "#{source}#{separator}tr=w-#{width},c-at_max,q-#{quality},f-auto"
  end

  def imagekit_srcset(source, widths:, quality: 80)
    widths.map { |width| "#{imagekit_url(source, width:, quality:)} #{width}w" }.join(", ")
  end

  def imagekit_image_tag(source, alt:, widths:, sizes:, class_name:, loading: "lazy", fetchpriority: nil, onerror: nil, width: nil, height: nil, quality: 80)
    image_tag(
      imagekit_url(source, width: widths.max, quality:),
      alt:,
      class: class_name,
      srcset: imagekit_srcset(source, widths:, quality:),
      sizes:,
      loading:,
      fetchpriority:,
      onerror:,
      width:,
      height:,
      decoding: "async"
    )
  end

  def euro_price(value)
    number_to_currency(value, unit: "€", format: "%u%n", precision: (value.to_f % 1).zero? ? 0 : 2, separator: ",", delimiter: ".")
  end
  PUBLIC_FULL_WIDTH_ACTIONS = {
    "domains" => %w[show],
    "demo/pages" => %w[mari carta_nautica],
    "home" => %w[index],
    "pages" => %w[flowpulse mari markpostura markpostura_old markposturastory posturacorretta],
    "nodes" => %w[show]
  }.freeze

  def full_width_layout?
    PUBLIC_FULL_WIDTH_ACTIONS.fetch(controller_path, []).include?(action_name)
  end

  def flowtree_public_node_path(node, *args)
    return nil if node.nil?
    node_path(node.resolve_target, *args)
  end

  def can_manage_nodes?(role_assignment)
    return false unless Current.user
    Current.user.superadmin_user? || (Current.user.creator_user? && Current.user.role_assignments.exists?(id: role_assignment&.id))
  end

  def current_brand_admin_node
    return @current_brand_admin_node if defined?(@current_brand_admin_node)
    return @current_brand_admin_node = nil unless Current.user

    domain_node = (Current.domain || current_domain)&.node
    path_slug = request.path.split("/").second
    candidate = domain_node&.brand? ? domain_node : Node.includes(:domains, role_assignment: :profile).find_by(slug: path_slug)

    @current_brand_admin_node = candidate if candidate&.brand? && candidate.administered_by?(Current.user)
  end
end
