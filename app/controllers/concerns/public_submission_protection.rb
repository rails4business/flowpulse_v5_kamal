module PublicSubmissionProtection
  extend ActiveSupport::Concern

  included do
    class_attribute :public_submission_actions, instance_writer: false, default: {}
  end

  class_methods do
    def protect_public_submission(action, form_key:, fallback: nil)
      self.public_submission_actions = public_submission_actions.merge(
        action.to_s => { form_key: form_key.to_s, fallback: fallback }
      ).freeze
      before_action :verify_public_submission!, only: action
    end
  end

  private

    def verify_public_submission!
      configuration = public_submission_actions.fetch(action_name)
      return reject_public_submission!(:oversized) if public_submission_oversized?
      return reject_public_submission!(:honeypot, silent: true) if params.dig(:submission_check, :website).present?

      token = params.dig(:submission_check, :token)
      unless Rails.env.test? && token.blank?
        valid_token = PublicSubmissionSecurity.verify_token(
          token,
          form_key: configuration.fetch(:form_key),
          host: request.host
        )
        return reject_public_submission!(:invalid_token) unless valid_token
      end

      apply_public_submission_rate_limits!(configuration.fetch(:form_key))
    end

    def apply_public_submission_rate_limits!(form_key)
      profile = PublicSubmissionSecurity.profile_for(public_submission_domain)
      host = Domain.normalize_host(request.host)
      rate_limiting(
        to: profile.fetch(:per_ip), within: profile.fetch(:within),
        by: -> { "#{host}:#{request.remote_ip}" }, with: :public_submission_rate_limited!,
        store: self.class.cache_store, name: "per-ip", scope: "public-submission:#{form_key}"
      )
      return if performed?

      rate_limiting(
        to: profile.fetch(:global), within: profile.fetch(:within),
        by: -> { host }, with: :public_submission_rate_limited!,
        store: self.class.cache_store, name: "per-domain", scope: "public-submission:#{form_key}"
      )
    end

    def public_submission_domain
      authentication_context_domain || current_domain&.canonical_domain_record || Domain.find_for_host(request.host)
    end

    def public_submission_oversized?
      request.content_length.to_i > PublicSubmissionSecurity::MAX_REQUEST_BYTES ||
        public_submission_scalar_values(params.to_unsafe_h).any? { |value| value.to_s.bytesize > PublicSubmissionSecurity::MAX_FIELD_BYTES }
    end

    def public_submission_scalar_values(value)
      case value
      when Hash then value.values.flat_map { |item| public_submission_scalar_values(item) }
      when Array then value.flat_map { |item| public_submission_scalar_values(item) }
      else [value]
      end
    end

    def public_submission_rate_limited!
      response.headers["Retry-After"] = "600"
      log_public_submission_rejection(:rate_limited)
      render plain: "Troppe richieste. Riprova tra qualche minuto.", status: :too_many_requests
    end

    def reject_public_submission!(reason, silent: false)
      configuration = public_submission_actions.fetch(action_name)
      log_public_submission_rejection(reason)
      target = configuration[:fallback]
      target = instance_exec(&target) if target.respond_to?(:call)
      target ||= request.referer.presence || root_path
      message = silent ? "Richiesta ricevuta." : "Non è stato possibile verificare il modulo. Ricarica la pagina e riprova."
      redirect_to target, notice: message
    end

    def log_public_submission_rejection(reason)
      Rails.logger.warn({
        event: "public_submission_rejected",
        reason: reason.to_s,
        controller: controller_path,
        action: action_name,
        host: Domain.normalize_host(request.host),
        ip_hash: Digest::SHA256.hexdigest("#{Rails.application.secret_key_base}:#{request.remote_ip}").first(16)
      }.to_json)
    end
end
