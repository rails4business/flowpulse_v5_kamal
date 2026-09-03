module Brands
  module Impegno
    class DataEventsController < ApplicationController
      layout "landing"

      before_action :require_superadmin
      before_action :set_data_event, only: %i[edit update show]
      before_action :set_form_options, only: %i[new create edit update]

      def index
        @domain_groups = grouped_active_domains
        @domains = @domain_groups.values.map { |domains| canonical_domain(domains) }.sort_by(&:hostname)
        @selected_domain = @domains.find { |domain| domain.id == params[:domain_id].to_i }
        @data_events = DataEvent.roots.includes(:domain, :responsible_profile).chronological
        @data_events = @data_events.where(domain_id: @domain_groups.fetch(domain_group_key(@selected_domain))) if @selected_domain
      end

      def new
        set_session_interval
        @data_event = DataEvent.new(
          domain: @domains.find { |domain| domain.id == params[:domain_id].to_i },
          classification: "event",
          node_kind: "root",
          status: "draft",
          visibility: "private"
        )
      end

      def show
        @tree_nodes = descendants_for(@data_event)
        @commitments_by_event_id = DataCommitment
          .where(data_event_id: @tree_nodes.map(&:id))
          .where.not(status: "cancelled")
          .includes(:profile, :assignee_profile, :participant_contact)
          .order(:starts_at, :id)
          .group_by(&:data_event_id)
      end

      def create
        set_session_interval
        @data_event = DataEvent.new(data_event_params)
        @data_event.node_kind = "root"
        @data_event.created_by_profile = current_profile
        apply_publication_state

        if save_root_with_optional_session
          redirect_to impegno_data_events_path(domain_id: @data_event.domain_id), notice: "Evento creato."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        @data_event.assign_attributes(data_event_params)
        apply_publication_state

        if @data_event.save
          redirect_to impegno_data_events_path(domain_id: @data_event.domain_id), notice: "Evento aggiornato."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

        def require_superadmin
          head :not_found unless Current.user&.superadmin_user?
        end

        def set_data_event
          @data_event = DataEvent.roots.includes(children: { children: { children: :children } }).find(params[:id])
          @days = @data_event.children.where(node_kind: "day").chronological
        end

        def set_form_options
          @domains = grouped_active_domains.values.map { |domains| canonical_domain(domains) }.sort_by(&:hostname)
          @responsible_profiles = Profile.order(:display_name, :username)
        end

        def grouped_active_domains
          Domain.active.order(:hostname).group_by { |domain| domain_group_key(domain) }
        end

        def domain_group_key(domain)
          return "node:#{domain.node_id}" if domain.node_id.present?

          "host:#{domain.hostname.sub(/\Awww\./, "")}" 
        end

        def canonical_domain(domains)
          domains.find(&:primary?) || domains.find { |domain| !domain.hostname.start_with?("www.") } || domains.first
        end

        def data_event_params
          params.require(:data_event).permit(:domain_id, :title, :description, :classification, :responsible_profile_id, :status, :visibility)
        end

        def apply_publication_state
          if @data_event.visibility == "public" && @data_event.status != "draft"
            @data_event.published_at ||= Time.current
          elsif @data_event.visibility == "private"
            @data_event.published_at = nil
          end
        end

        def set_session_interval
          @session_starts_at = params[:session_starts_at].presence
          @session_ends_at = params[:session_ends_at].presence
        end

        def save_root_with_optional_session
          return @data_event.save if @session_starts_at.blank? && @session_ends_at.blank?
          if @session_starts_at.blank? || @session_ends_at.blank?
            @data_event.errors.add(:base, "Inserisci sia l’inizio sia la fine dell’appuntamento")
            return false
          end

          starts_at = Time.zone.parse(@session_starts_at)
          ends_at = Time.zone.parse(@session_ends_at)
          DataEvent.transaction do
            @data_event.save!
            day = @data_event.children.create!(
              title: "Fascia · #{starts_at.strftime('%d/%m/%Y')}", node_kind: "day",
              domain: @data_event.domain, created_by_profile: current_profile,
              responsible_profile: @data_event.responsible_profile,
              starts_at:, ends_at:, status: child_status, visibility: @data_event.visibility,
              published_at: @data_event.published_at
            )
            day.children.create!(
              title: @data_event.title, node_kind: "session",
              domain: @data_event.domain, created_by_profile: current_profile,
              responsible_profile: @data_event.responsible_profile,
              starts_at:, ends_at:, status: child_status, visibility: @data_event.visibility,
              published_at: @data_event.published_at, bookable: true,
              booking_mode: "session", registration_mode: "required", registration_status: "open"
            )
          end
          true
        rescue ActiveRecord::RecordInvalid => error
          @data_event.errors.add(:base, error.record.errors.full_messages.to_sentence) unless error.record == @data_event
          false
        rescue ArgumentError
          @data_event.errors.add(:base, "Data o orario dell’appuntamento non validi")
          false
        end

        def child_status
          @data_event.draft? ? "draft" : "proposed"
        end

        def descendants_for(root)
          nodes = []
          queue = [root]
          until queue.empty?
            node = queue.shift
            nodes << node
            queue.concat(node.children.to_a)
          end
          nodes
        end
    end
  end
end
