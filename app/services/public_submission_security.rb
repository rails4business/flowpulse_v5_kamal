class PublicSubmissionSecurity
  PROFILES = {
    "standard" => { per_ip: 5, global: 100, within: 10.minutes },
    "sensitive" => { per_ip: 3, global: 50, within: 15.minutes },
    "api" => { per_ip: 30, global: 300, within: 1.minute }
  }.freeze

  TOKEN_PURPOSE = "public-submission-form".freeze
  TOKEN_MAX_AGE = 2.hours
  MINIMUM_FILL_TIME = 3.seconds
  MAX_REQUEST_BYTES = 64.kilobytes
  MAX_FIELD_BYTES = 5_000

  class << self
    def profile_for(domain)
      key = domain&.canonical_domain_record&.security_profile.to_s.presence_in(PROFILES.keys) || "standard"
      PROFILES.fetch(key).merge(key: key)
    end

    def generate_token(form_key:, host:, issued_at: Time.current)
      verifier.generate(
        { "form_key" => form_key.to_s, "host" => Domain.normalize_host(host), "issued_at" => issued_at.to_f },
        purpose: TOKEN_PURPOSE
      )
    end

    def verify_token(token, form_key:, host:, now: Time.current, minimum_fill_time: default_minimum_fill_time)
      payload = verifier.verified(token.to_s, purpose: TOKEN_PURPOSE)
      return false unless payload.is_a?(Hash)
      return false unless ActiveSupport::SecurityUtils.secure_compare(payload["form_key"].to_s, form_key.to_s)
      return false unless ActiveSupport::SecurityUtils.secure_compare(payload["host"].to_s, Domain.normalize_host(host))

      issued_at = Time.zone.at(Float(payload["issued_at"], exception: false) || 0)
      age = now - issued_at
      age >= minimum_fill_time && age <= TOKEN_MAX_AGE
    rescue ActiveSupport::MessageVerifier::InvalidSignature, TypeError, ArgumentError
      false
    end

    private

      def verifier
        Rails.application.message_verifier(:public_submission)
      end

      def default_minimum_fill_time
        Rails.env.test? ? 0.seconds : MINIMUM_FILL_TIME
      end
  end
end
