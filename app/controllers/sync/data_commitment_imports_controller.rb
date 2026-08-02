require "json"

module Sync
  class DataCommitmentImportsController < ApplicationController
    allow_unauthenticated_access
    skip_forgery_protection
    before_action :authenticate_sync_token!

    def create
      payload = JSON.parse(request.raw_post)
      unless DataCommitmentTransfer.valid_payload?(payload)
        return render json: { error: "Payload DataCommitment non valido" }, status: :unprocessable_entity
      end

      target_username = payload["target_profile_username"].presence || Array(payload["commitments"]).first["profile_username"]
      target_profile = Profile.find_by(username: target_username)
      return render json: { error: "Profilo destinatario non trovato" }, status: :unprocessable_entity if target_profile.blank?

      records = Array(payload["commitments"])
      return render json: { error: "Il file deve contenere impegni di un solo profilo" }, status: :unprocessable_entity if records.any? { |item| item["profile_username"] != target_profile.username }

      fingerprint = DataCommitmentTransfer.fingerprint(payload)
      import = DataCommitmentImport.find_or_initialize_by(source_fingerprint: fingerprint)
      created = import.new_record?
      import.assign_attributes(
        uploaded_by_user: target_profile.user,
        target_profile: target_profile,
        source_name: payload["source_name"].presence || "Esportazione locale #{payload["exported_at"]}",
        source_type: "deploy_queue",
        payload: payload,
        summary: DataCommitmentTransfer.summary(records)
      )
      import.save! if created

      render json: { status: created ? "pending_confirmation" : import.status, import_id: import.id, target_profile: target_profile.username }, status: created ? :created : :ok
    rescue JSON::ParserError
      render json: { error: "JSON non valido" }, status: :unprocessable_entity
    end

    private

      def authenticate_sync_token!
        expected = ENV.fetch("DATA_COMMITMENT_SYNC_TOKEN", "")
        provided = request.authorization.to_s.delete_prefix("Bearer ")
        return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(provided, expected)

        render json: { error: "Non autorizzato" }, status: :unauthorized
      end
  end
end
