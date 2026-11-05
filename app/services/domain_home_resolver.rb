class DomainHomeResolver
  def initialize(domain, site_key: nil)
    @domain = domain
    @site_key = site_key.presence
  end

  def call
    return :fallback if domain.blank?

    case domain.resolved_home_mode
    when "node"
      domain.node.present? ? :node : :misconfigured
    when "site"
      site_key.present? ? :site : :misconfigured
    when "target"
      target_configured? ? :target : :misconfigured
    else
      automatic_renderer
    end
  end

  private

  attr_reader :domain, :site_key

  def automatic_renderer
    return :site if site_key.present?
    return :target if target_configured?
    return :node if domain.node.present?
    return :creator if domain.role_assignment.present?

    :fallback
  end

  def target_configured?
    domain.target_controller.present? && domain.target_action.present?
  end
end
