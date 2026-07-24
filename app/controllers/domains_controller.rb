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
      if Current.domain&.target_controller.present?
        render_domain_target
      elsif Current.domain&.node.present? && render_public_node(Current.domain.node)
        # successfully rendered assigned node
      elsif Current.domain&.role_assignment.present? && (creator_node = Current.domain.role_assignment.nodes.roots.published_free.order(:position, :title).find { |node| public_node_visible?(node) }) && render_public_node(creator_node)
        # successfully rendered creator's home/first root node
      else
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
      else
        render "#{target_controller}/#{target_action}"
      end
    end

    def prepare_landing_target(target_action)
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
end
