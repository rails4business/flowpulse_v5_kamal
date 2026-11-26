module Brands
  module Admin
    class BrandRequestsController < BaseController
      STATE_TRANSITIONS = {
        "take_charge" => "in_progress",
        "wait" => "waiting",
        "accept" => "accepted",
        "close" => "closed",
        "reject" => "rejected",
        "cancel" => "cancelled",
        "reopen" => "open"
      }.freeze

      def index
        scope = brand_requests
        @status_counts = scope.group(:status).count
        @state_counts = {
          "open" => scope.active.count,
          "closed" => scope.closed.count
        }
        @active_state = params[:state].presence_in(%w[open closed all]) || "open"
        scope = scope.active if @active_state == "open"
        scope = scope.closed if @active_state == "closed"

        if @active_state == "closed"
          @active_status = params[:status].presence_in(%w[accepted rejected closed])
          if @active_status == "rejected"
            scope = scope.where(status: %w[rejected cancelled])
          elsif @active_status.present?
            scope = scope.where(status: @active_status)
          end
        else
          @active_status = nil
        end

        @requests = scope
          .includes(:domain, :participant_contact, :subject, :requester_profile, :assigned_to_profile, :brand_invitations)
          .order(created_at: :desc)
          .limit(250)
      end

      def update_state
        brand_request = brand_requests.find(params[:id])
        target_status = STATE_TRANSITIONS[params[:transition].to_s]
        return redirect_to(brand_admin_requests_path(@brand.slug), alert: "Azione non valida.") unless target_status

        attributes = { status: target_status }
        attributes[:assigned_to_profile] = Current.user.profile if target_status == "in_progress"
        attributes[:resolved_at] = BrandRequest::CLOSED_STATUSES.include?(target_status) ? Time.current : nil
        brand_request.update!(attributes)

        if params[:transition] == "reject"
          return redirect_to brand_admin_requests_path(@brand.slug, state: "open"), notice: "Richiesta rifiutata."
        end

        state = BrandRequest::CLOSED_STATUSES.include?(target_status) ? "closed" : "open"
        redirect_to brand_admin_requests_path(@brand.slug, state:, anchor: "brand-request-#{brand_request.id}"), notice: "Richiesta aggiornata."
      end

      def create_invitation
        brand_request = brand_requests.includes(:participant_contact, :domain, :brand_invitations).find(params[:id])
        unless brand_request.kind == "access" && brand_request.participant_contact&.email.present?
          return redirect_to brand_admin_requests_path(@brand.slug), alert: "Questa richiesta non può generare un invito."
        end

        invitation, raw_token = BrandInvitations::Issuer.new(actor: Current.user, context: dashboard_access_context).issue!(
          domain: brand_request.domain, email_address: brand_request.participant_contact.email,
          brand_request: brand_request
        )

        flash[:invitation_url] = invitation_link(invitation, raw_token)
        redirect_to brand_admin_requests_path(@brand.slug, state: "open", anchor: "brand-request-#{brand_request.id}"), notice: "Invito generato. Copia il collegamento e invialo personalmente."
      rescue BrandAccesses::Authorization::NotAuthorized, ArgumentError, ActiveRecord::RecordInvalid => error
        redirect_to brand_admin_requests_path(@brand.slug, state: "open"), alert: error.message
      end

      def approve_access
        brand_request = brand_requests.find(params[:id])
        access = BrandRequests::AccessApprover.new(actor: Current.user, context: dashboard_access_context).approve!(brand_request)
        redirect_to brand_admin_requests_path(@brand.slug, state: "closed", status: "accepted", anchor: "brand-request-#{brand_request.id}"), notice: "Accesso a #{access.brand_node.title} concesso."
      rescue ActiveRecord::RecordInvalid, ArgumentError, BrandRequests::AccessApprover::NotAuthorized, BrandAccesses::Manager::NotAuthorized => error
        redirect_to brand_admin_requests_path(@brand.slug, state: "open", anchor: "brand-request-#{params[:id]}"), alert: error.message
      end

      def destroy
        brand_request = brand_requests.find(params[:id])
        unless brand_request.safely_destroyable?
          redirect_to brand_admin_requests_path(@brand.slug, state: "all", anchor: "brand-request-#{brand_request.id}"),
            alert: "La richiesta ha già prodotto accessi o attività: conservala nello storico."
          return
        end

        brand_request.brand_invitations.pending.update_all(status: "revoked", updated_at: Time.current)
        brand_request.destroy!
        redirect_to brand_admin_requests_path(@brand.slug, state: "all"), notice: "Richiesta eliminata definitivamente."
      end

      private

        def brand_requests
          return all_brand_requests if full_brand_request_access?

          BrandRequest.where(subject_type: "Node", subject_id: managed_request_node_ids)
            .where(brand_node: @brand)
        end

        def all_brand_requests
          domain_ids = @brand.domains.select(:id)
          node_ids = @brand.self_and_descendants.select(:id)

          BrandRequest.where(brand_node: @brand).or(
            BrandRequest.where(domain_id: domain_ids)
          ).or(
            BrandRequest.where(subject_type: "Node", subject_id: node_ids)
          )
        end

        def full_brand_request_access?
          return Current.user&.superadmin_user? || genera_impresa_manager? if @brand.slug == "generaimpresa"

          Current.user&.superadmin_user? || @brand.owned_by?(Current.user)
        end

        def managed_request_node_ids
          @managed_request_node_ids ||= begin
            context = RoleAssignments::AccessPolicy.current_context(user: Current.user, context: dashboard_access_context)
            if context&.brand == @brand && context.current_role_code == "imprenditore_generaimpresa"
              context.current_role_assignment.context.self_and_descendants.select { |node| node.site_node == @brand }.map(&:id)
            else
              []
            end
          end
        end

        def genera_impresa_manager?
          DashboardNavigation::Policy.new(context: dashboard_access_context).allowed?(:requests)
        end

        def invitation_link(invitation, raw_token)
          if local_request?
            brand_invitation_url(raw_token, host: "localhost", port: request.optional_port, protocol: request.protocol)
          else
            brand_invitation_url(raw_token, host: invitation.source_domain.hostname, protocol: "https")
          end
        end
    end
  end
end
