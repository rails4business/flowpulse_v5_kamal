class ApplicationController < ActionController::Base
  include Authentication
  include CurrentDomain
  include FlowRoles::ControllerHelpers
  helper_method :dashboard_current_section
  helper_method :public_node_visible?, :public_node_navigable?, :public_node_accessible_children
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

    def dashboard_current_section
      @dashboard_current_section || :dashboard
    end

    def public_node_visible?(node)
      return false if node.blank?
      return true if Current.user&.superadmin_user?
      return true if creator_can_manage_node?(node)
      return true if node.status == "published" && node.visibility == "public"
      return true if node.status == "published" && node.visibility == "subscription" && traveler_subscribed_to_node?(node)

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
      return false unless Current.user&.creator_user?

      Current.user.role_assignment_ids.include?(node.role_assignment_id)
    end

    def traveler_subscribed_to_node?(node)
      profile = Current.user&.profile
      return false if profile.blank?

      ancestor_node_ids = node.self_and_ancestors.select(:id)
      subscribed_domain_ids = profile.traveler_subscriptions.active.select(:domain_id)

      Domain.active.where(node_id: ancestor_node_ids, id: subscribed_domain_ids).exists?
    end

    def subscribe_current_user_to_domain(domain)
      return if Current.user.blank? || domain.blank?

      profile = Current.user.profile || Current.user.create_profile!(display_name: Current.user.email_address.to_s.split("@").first)
      subscription = profile.traveler_subscriptions.find_or_initialize_by(domain: domain)
      subscription.node = domain.node
      subscription.status = "active"
      subscription.subscribed_at ||= Time.current
      subscription.save!
    end

    def require_permission!(resource, action = :read)
      return if FlowRoles.can?(Current.user, action, resource)

      redirect_to dashboard_home_path, alert: "Accesso non disponibile per il ruolo attivo."
    end

    def ensure_active_role_assignment
      return unless authenticated?
      user = Current.user
      return unless user

      role = user.active_role.to_s
      ra = user.current_role_assignment

      if %w[traveler superadmin].include?(role)
        if ra.present?
          user.update!(current_role_assignment: nil)
        end
        return
      end

      mapped_role = case role
                    when "creator" then "creator_of_worlds"
                    when "admin" then "segreteria_amministrativa"
                    else role
                    end

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
