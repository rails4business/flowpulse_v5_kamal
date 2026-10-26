class PublicBrandRequestsController < ApplicationController
  allow_unauthenticated_access
  protect_public_submission :create, form_key: "public_brand_request",
    fallback: -> { request.referer.presence || root_path }

  PUBLIC_KINDS = %w[waitlist contact information event service].freeze

  def create
    attributes = request_params
    brand_node = Node.find_by!(slug: attributes.fetch(:brand_slug))
    domain = brand_node.domains.active.find_by(primary: true) || brand_node.domains.active.first!
    owner_profile = brand_node.role_assignment.profile

    unless attributes[:privacy_consent] == "1"
      return redirect_to(safe_return_to(attributes[:return_to], brand_node), alert: "Conferma di aver letto l’informativa privacy.")
    end
    if attributes[:name].blank? || attributes[:email].blank?
      return redirect_to(safe_return_to(attributes[:return_to], brand_node), alert: "Inserisci nome e indirizzo email.")
    end

    open_request = BrandRequest.active
      .joins(:participant_contact)
      .where(domain:, kind: attributes.fetch(:kind))
      .where("LOWER(impegno_contacts.email) = ?", attributes.fetch(:email))
      .first

    unless open_request
      ActiveRecord::Base.transaction do
        contact = owner_profile.impegno_contacts.create!(
          name: attributes.fetch(:name),
          email: attributes.fetch(:email),
          phone: attributes[:phone],
          metadata: {
            "source_domain" => domain.hostname,
            "privacy_notice_acknowledged_at" => Time.current.iso8601,
            "privacy_notice_version" => "2026-10-16"
          }
        )
        BrandRequest.create!(
          domain:,
          brand_node:,
          requester_profile: Current.user&.profile,
          participant_contact: contact,
          subject: brand_node,
          kind: attributes.fetch(:kind),
          status: attributes.fetch(:kind) == "waitlist" ? "waiting" : "open",
          audience: "user",
          title: attributes[:title].presence || "Richiesta da #{brand_node.title}",
          message: attributes[:message],
          source_url: request.referer,
          metadata: { "source_domain" => domain.hostname }
        )
      end
    end

    redirect_to safe_return_to(attributes[:return_to], brand_node), notice: "Richiesta ricevuta. Ti avviserò quando sarà disponibile il prossimo incontro."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to safe_return_to(attributes&.dig(:return_to), brand_node), alert: error.record.errors.full_messages.to_sentence
  end

  private

    def request_params
      params.require(:brand_request).permit(
        :brand_slug, :kind, :title, :name, :email, :phone, :message, :privacy_consent, :return_to
      ).to_h.symbolize_keys.tap do |attrs|
        attrs[:brand_slug] = attrs[:brand_slug].to_s.strip
        attrs[:kind] = attrs[:kind].presence_in(PUBLIC_KINDS) || "contact"
        attrs[:name] = attrs[:name].to_s.strip
        attrs[:email] = attrs[:email].to_s.strip.downcase
        attrs[:phone] = attrs[:phone].to_s.strip.presence
        attrs[:message] = attrs[:message].to_s.strip.presence
      end
    end

    def safe_return_to(value, brand_node)
      path = value.to_s
      return path if path.start_with?("/") && !path.start_with?("//")

      "/#{brand_node.slug}"
    end
end
