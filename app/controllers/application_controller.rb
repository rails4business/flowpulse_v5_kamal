class ApplicationController < ActionController::Base
  include Authentication
  include AuthenticationBrandContext
  include CurrentDomain
  include CanonicalBrandHost
  include EditorialRendering
  include FlowRoles::ControllerHelpers
  helper_method :dashboard_current_section
  helper_method :active_data_commitment
  helper_method :public_node_visible?, :public_node_navigable?, :public_node_accessible_children
  helper_method :pwa_site_config
  helper_method :privacy_preferences_config
  before_action :resume_session
  before_action :ensure_active_role_assignment
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  DASHBOARD_ROLES = User::SWITCHABLE_ROLES.map { |role| [ role, User::ROLE_LABELS.fetch(role, role.titleize) ] }.freeze

  def self.dashboard_section(section, **options)
    before_action(**options) do
      @dashboard_current_section = section.to_sym
    end
  end

  private

    def pwa_site_config
      @pwa_site_config ||= Pwa::SiteConfig.for(request:, domain: current_domain)
    end

    def privacy_preferences_config
      host = current_domain&.hostname.presence || current_domain_host
      host = "corpoecoscienza.org" if controller_path == "brands/corpo_e_coscienza"
      @privacy_preferences_config ||= PrivacyCatalog.for(host: host)
    end

    def current_profile
      return unless Current.user

      Current.user.profile || Current.user.create_profile!(display_name: Current.user.email_address.to_s.split("@").first)
    end

    def active_data_commitment
      return unless Current.user&.profile

      @active_data_commitment ||= Current.user.profile.data_commitments
        .where(status: "in_progress", actual_ended_at: nil)
        .order(actual_started_at: :desc)
        .first
    end

    def dashboard_current_section
      @dashboard_current_section || :dashboard
    end

    def available_commitment_nodes
      return Node.order(:title, :id) if Current.user&.superadmin_user?
      return Node.none unless Current.user

      ids = Node.includes(:role_assignment).select { |node| node.administered_by?(Current.user) }.map(&:id)
      Node.where(id: ids).order(:title, :id)
    end

    def public_node_visible?(node)
      return false if node.blank?
      return true if Current.user&.superadmin_user?
      return true if creator_can_manage_node?(node)
      return true if PublicDiscovery::AccessPolicy.new.public_node?(node)
      return true if node.status == "published" && node.visibility == "subscription" && brand_access_grants_node?(node)

      false
    end

    def public_node_navigable?(node)
      return false unless public_node_visible?(node)
      return true unless node.bridge_node?

      target = node.resolve_target
      target == node || public_node_visible?(target)
    end

    def public_node_accessible_children(node)
      return [] if node.blank?

      node.children.order(:position, :title).select { |child| public_node_navigable?(child) }
    end

    def creator_can_manage_node?(node)
      return false unless Current.user&.ideatore_user?

      Current.user.role_assignment_ids.include?(node.role_assignment_id)
    end

    def brand_access_grants_node?(node)
      profile = Current.user&.profile
      return false if profile.blank?

      ancestor_node_ids = node.self_and_ancestors.select(:id)
      profile.brand_accesses.active.where(brand_node_id: ancestor_node_ids).exists?
    end

    def grant_current_user_brand_access!(domain)
      return if Current.user.blank? || domain.blank?

      ensure_profile_domain_access!(current_profile, domain).fetch(:brand_access)
    end

    def grant_profile_brand_access!(profile, domain)
      return if profile.blank? || domain.blank? || domain.node_id.blank?

      access = profile.brand_accesses.find_or_initialize_by(brand_node_id: domain.node_id)
      access.source_domain ||= domain
      access.brand_node = domain.node
      access.status = "active"
      access.joined_at ||= Time.current
      access.save!
      access
    end

    def ensure_current_user_site_access!(domain)
      return if Current.user.blank? || domain.blank?

      ensure_profile_domain_access!(current_profile, domain)
    end

    def ensure_profile_domain_access!(profile, domain)
      return if profile.blank? || domain.blank?
      raise ArgumentError, "Il Domain deve essere collegato a un Node" if domain.node_id.blank?

      brand_access = grant_profile_brand_access!(profile, domain)
      domain_access = profile.domain_accesses.find_or_initialize_by(domain: domain)
      domain_access.brand_access = brand_access
      domain_access.status = "active"
      domain_access.activated_at ||= Time.current
      domain_access.last_accessed_at = Time.current
      domain_access.save!

      { brand_access: brand_access, domain_access: domain_access }
    end

    def require_permission!(resource, action = :read)
      return if FlowRoles.can?(Current.user, action, resource)

      redirect_to dashboard_home_path, alert: "Accesso non disponibile per il ruolo attivo."
    end

    def ensure_active_role_assignment
      return unless authenticated?
      user = Current.user
      return unless user

      unless user.active_role_attivabile?
        fallback_role = user.superadmin_user? ? "superadmin" : "traveler"
        user.update!(active_role: fallback_role, current_role_assignment: nil)
      end

      role = user.active_role.to_s
      ra = user.current_role_assignment

      if %w[traveler admin superadmin].include?(role)
        if ra.present?
          user.update!(current_role_assignment: nil)
        end
        return
      end

      mapped_role = role

      if ra.nil? || ra.role.to_s != mapped_role
        new_ra = user.role_assignments.find_by(role: mapped_role)
        if new_ra.nil? && user.superadmin_user?
          new_ra = RoleAssignment.find_by(role: mapped_role)
        end

        if new_ra
          user.update!(current_role_assignment: new_ra)
        end
      end
    end
end
