class BrandAccessRequestsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access
  rate_limit to: 5, within: 10.minutes, only: :create,
    with: -> { redirect_to new_brand_access_request_path, alert: "Hai inviato troppe richieste. Riprova tra qualche minuto." }

  before_action :set_request_domain

  def new
  end

  def create
    attributes = request_params
    unless attributes[:privacy_consent] == "1"
      return redirect_to(new_brand_access_request_path(context_params), alert: "Conferma di aver letto l’informativa privacy.")
    end
    if attributes[:name].blank? || attributes[:email].blank?
      return redirect_to(new_brand_access_request_path(context_params), alert: "Inserisci nome e indirizzo email.")
    end

    owner_profile = @request_domain.node.role_assignment.profile
    open_request = owner_profile.data_commitments
      .joins(:participant_contact)
      .where(domain: @request_domain, status: %w[requested in_progress])
      .where("data_commitments.metadata ->> 'request_kind' = ?", "access_invitation")
      .where("LOWER(impegno_contacts.email) = ?", attributes[:email].downcase)
      .first

    unless open_request
      ActiveRecord::Base.transaction do
        contact = owner_profile.impegno_contacts.create!(
          name: attributes[:name],
          email: attributes[:email],
          phone: attributes[:phone],
          metadata: {
            "source_domain" => @request_domain.hostname,
            "privacy_notice_acknowledged_at" => Time.current.iso8601,
            "privacy_notice_version" => "2026-10-13"
          }
        )
        owner_profile.data_commitments.create!(
          created_by_profile: owner_profile,
          domain: @request_domain,
          subject: @request_domain.node,
          participant_contact: contact,
          title: "Richiesta di accesso a #{@request_domain.authentication_sender_name}",
          description: attributes[:message],
          kind: "service",
          status: "requested",
          starts_at: nil,
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid",
          calendar_key: "brand:#{@request_domain.node_id}:requests",
          calendar_label: "Richieste · #{@request_domain.authentication_sender_name}",
          metadata: {
            "request_kind" => "access_invitation",
            "request_audience" => "user",
            "source_domain" => @request_domain.hostname
          }
        )
      end
    end

    redirect_to new_brand_access_request_path(context_params), notice: "Richiesta ricevuta. Il responsabile del Brand potrà inviarti personalmente il link d’invito."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to new_brand_access_request_path(context_params), alert: error.record.errors.full_messages.to_sentence
  end

  private
    def set_request_domain
      @request_domain = authentication_context_domain || current_domain&.canonical_domain_record
      raise ActiveRecord::RecordNotFound unless @request_domain&.active? && @request_domain.node.present?
    end

    def request_params
      params.require(:access_request).permit(:name, :email, :phone, :message, :privacy_consent).to_h.symbolize_keys.tap do |attrs|
        attrs[:name] = attrs[:name].to_s.strip
        attrs[:email] = attrs[:email].to_s.strip.downcase
        attrs[:phone] = attrs[:phone].to_s.strip.presence
        attrs[:message] = attrs[:message].to_s.strip.presence
      end
    end

    def context_params
      local_request? && authentication_context_site.present? ? { site: authentication_context_site } : {}
    end
end
