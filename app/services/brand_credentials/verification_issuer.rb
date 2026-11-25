module BrandCredentials
  class VerificationIssuer
    Result = Data.define(:verification, :confirmation_url)

    def issue!(brand_access)
      credential = brand_access.brand_credential
      raise ArgumentError, "La credenziale del Brand non esiste" if credential.blank?
      raise ArgumentError, "La credenziale non è in attesa di verifica" unless credential.status == "pending_verification"

      user = brand_access.profile.user
      raise ArgumentError, "Il Profile non possiede ancora un’identità utilizzabile" if user.blank?
      unless credential.email_address.casecmp?(user.email_address)
        raise ArgumentError, "L’email della credenziale non coincide con quella del Profile"
      end

      domain = brand_access.source_domain.canonical_domain_record
      verification, raw_token = EmailVerification.issue!(
        user:,
        brand_node: brand_access.brand_node,
        requested_domain: domain,
        return_to: domain.auth_default_path
      )
      confirmation_url = Rails.application.routes.url_helpers.email_verification_url(
        token: raw_token,
        host: domain.hostname,
        protocol: "https"
      )
      Result.new(verification:, confirmation_url:)
    end
  end
end
