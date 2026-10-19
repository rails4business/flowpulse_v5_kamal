module Brands
  module Admin
    class DataCommitmentsController < BaseController
      OPEN_STATUSES = %w[draft requested planned confirmed in_progress].freeze
      CLOSED_STATUSES = %w[completed cancelled].freeze
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

      private

        def brand_commitments
          domain_ids = @brand.domains.select(:id)
          node_ids = @brand.self_and_descendants.select(:id)
          commitments = Brands::Impegno::Commitment.all

          scope = commitments.where(domain_id: domain_ids).or(
            commitments.where(subject_type: "Node", subject_id: node_ids)
          )
          scope.where.not(id: BrandRequest.where.not(legacy_data_commitment_id: nil).select(:legacy_data_commitment_id))
        end
    end
  end
end
