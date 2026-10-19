module Brands
  module Admin
    class DataCommitmentsController < BaseController
      OPEN_STATUSES = %w[draft requested planned confirmed in_progress].freeze
      CLOSED_STATUSES = %w[completed cancelled].freeze
      STATE_TRANSITIONS = {
        "take_charge" => "in_progress",
        "complete" => "completed",
        "cancel" => "cancelled",
        "reopen" => "requested"
      }.freeze

      def index
        scope = brand_commitments
        @status_counts = scope.group(:status).count
        @state_counts = {
          "open" => scope.where(status: OPEN_STATUSES).count,
          "closed" => scope.where(status: CLOSED_STATUSES).count
        }
        @active_state = params[:state].presence_in(%w[open closed all]) || "open"
        scope = scope.where(status: OPEN_STATUSES) if @active_state == "open"
        scope = scope.where(status: CLOSED_STATUSES) if @active_state == "closed"
        @active_status = params[:status].presence_in(Brands::Impegno::Commitment::STATUSES)
        scope = scope.where(status: @active_status) if @active_status
        @commitments = scope
          .includes(:domain, :participant_contact, :subject, :created_by_profile, :assignee_profile)
          .order(Arel.sql("COALESCE(data_commitments.starts_at, data_commitments.created_at) DESC"))
          .limit(250)
      end

      def update_state
        commitment = brand_commitments.find(params[:id])
        transition = params[:transition].to_s
        target_status = STATE_TRANSITIONS[transition]
        return redirect_to(brand_admin_data_commitments_path(@brand.slug), alert: "Azione non valida.") unless target_status

        commitment.update!(
          status: target_status,
          resolved_at: CLOSED_STATUSES.include?(target_status) ? Time.current : nil
        )
        redirect_to brand_admin_data_commitments_path(@brand.slug, state: CLOSED_STATUSES.include?(target_status) ? "closed" : "open", anchor: "data-commitment-#{commitment.id}"), notice: "Richiesta aggiornata."
      end

      def create_invitation
        commitment = brand_commitments.includes(:participant_contact, :domain).find(params[:id])
        unless commitment.metadata.to_h["request_kind"] == "access_invitation" && commitment.participant_contact&.email.present?
          return redirect_to brand_admin_data_commitments_path(@brand.slug), alert: "Questa richiesta non può generare un invito."
        end

        previous_id = commitment.metadata.to_h["brand_invitation_id"]
        BrandInvitation.pending.find_by(id: previous_id)&.update!(status: "revoked") if previous_id.present?
        invitation, raw_token = BrandInvitation.issue!(
          brand_node: @brand,
          source_domain: commitment.domain.canonical_domain_record,
          email_address: commitment.participant_contact.email,
          invited_by_user: Current.user
        )
        commitment.update!(
          status: "in_progress",
          metadata: commitment.metadata.to_h.merge(
            "brand_invitation_id" => invitation.id,
            "invited_by_profile_id" => Current.user.profile&.id,
            "invitation_created_at" => Time.current.iso8601
          )
        )

        flash[:invitation_url] = invitation_link(invitation, raw_token)
        redirect_to brand_admin_data_commitments_path(@brand.slug, state: "open", anchor: "data-commitment-#{commitment.id}"), notice: "Invito generato. Copia il collegamento e invialo personalmente."
      end

      private

        def brand_commitments
          domain_ids = @brand.domains.select(:id)
          node_ids = @brand.self_and_descendants.select(:id)
          commitments = Brands::Impegno::Commitment.all

          commitments.where(domain_id: domain_ids).or(
            commitments.where(subject_type: "Node", subject_id: node_ids)
          )
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
