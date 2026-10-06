module Brands
  class CorpoECoscienzaController < ApplicationController
    layout "landing"
    allow_unauthenticated_access

    REQUEST_KINDS = %w[group_path individual_treatment events information training find_professional professional_application other].freeze

    def index
      load_site
      @request_kind = params[:request_kind].presence_in(REQUEST_KINDS) || "professional_application"
      @request_tab = if @request_kind == "professional_application" || @request_kind == "training"
        "professional_application"
      elsif %w[group_path individual_treatment events find_professional].include?(@request_kind)
        "find_professional"
      else
        "information"
      end
    end

    def locations
      query = params[:q].to_s.squish
      return render json: [] if query.length < 3

      render json: LocationSearch.call(
        query: query,
        country_code: params[:country_code],
        language: "it"
      )
    end

    def create_request
      domain = Domain.find_for_host(request.host) || Domain.find_for_host("corpoecoscienza.org")
      node = domain&.node || Node.find_by(slug: "corpoecoscienza")
      owner_profile = node&.role_assignment&.profile
      raise ActiveRecord::RecordNotFound, "Brand Corpo e Coscienza non configurato" unless domain && node && owner_profile

      attributes = request_params
      unless attributes[:privacy_consent] == "1"
        return redirect_to(corpo_e_coscienza_path(anchor: "richiesta"), alert: "Devi accettare l’informativa per inviare la richiesta.")
      end
      if attributes[:email].blank? && attributes[:phone].blank?
        return redirect_to(corpo_e_coscienza_path(anchor: "richiesta"), alert: "Indica almeno un indirizzo email o un numero di telefono.")
      end
      if attributes[:name].blank? || attributes[:message].blank?
        return redirect_to(corpo_e_coscienza_path(anchor: "richiesta"), alert: "Indica il tuo nome e scrivi un breve messaggio.")
      end

      ActiveRecord::Base.transaction do
        contact = owner_profile.impegno_contacts.create!(
          name: attributes.fetch(:name),
          email: attributes[:email],
          phone: attributes[:phone],
          notes: attributes[:city].present? ? "Località: #{attributes[:city]}" : nil,
          metadata: {
            "source_domain" => domain.hostname,
            "privacy_consent_at" => Time.current.iso8601
          }
        )

        owner_profile.data_commitments.create!(
          created_by_profile: owner_profile,
          domain: domain,
          subject: node,
          participant_contact: contact,
          title: request_title(attributes.fetch(:request_kind)),
          description: attributes.fetch(:message),
          kind: "service",
          status: "requested",
          starts_at: nil,
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid",
          calendar_key: "brand:#{node.id}:requests",
          calendar_label: "Richieste · Corpo e Coscienza",
          metadata: {
            "request_kind" => attributes.fetch(:request_kind),
            "source_domain" => domain.hostname,
            "source_url" => request.referer.to_s.presence || corpo_e_coscienza_url,
            "city" => attributes[:city].to_s.strip.presence,
            "country_code" => attributes[:country_code],
            "latitude" => decimal_or_nil(attributes[:latitude]),
            "longitude" => decimal_or_nil(attributes[:longitude]),
            "location_ref" => attributes[:location_ref]
          }.compact
        )
      end

      redirect_to corpo_e_coscienza_path(anchor: "richiesta"), notice: "Richiesta ricevuta. Ti ricontatteremo usando i recapiti indicati."
    rescue ActiveRecord::RecordInvalid => error
      redirect_to corpo_e_coscienza_path(anchor: "richiesta"), alert: error.record.errors.full_messages.to_sentence
    end

    private

      def load_site
        root = Rails.root.join("config/data/brands/corpoecoscienza").cleanpath
        @site = YAML.safe_load_file(root.join("site.yml"), permitted_classes: [], aliases: false) || {}
        @method_markdown = root.join("pages/metodo.md").read
        @founder_markdown = root.join("pages/georges-courchinoux.md").read
        professionals = YAML.safe_load_file(root.join("professionals/index.yml"), permitted_classes: [], aliases: false) || {}
        @professionals = professionals.fetch("professionals", []).select { |item| item.fetch("public", false) }.map do |item|
          source = root.join("professionals", item.fetch("source")).cleanpath
          next unless source.to_s.start_with?(root.join("professionals").to_s) && source.file?

          item.merge("body" => source.read)
        end.compact
        @professional_map_points = @professionals.filter_map do |professional|
          latitude = Float(professional["latitude"], exception: false)
          longitude = Float(professional["longitude"], exception: false)
          next unless latitude && longitude

          professional.slice("name", "city").merge("latitude" => latitude, "longitude" => longitude)
        end
      end

      def request_params
        params.require(:request).permit(:request_kind, :name, :email, :phone, :country_code, :city, :latitude, :longitude, :location_ref, :message, :privacy_consent).to_h.symbolize_keys.tap do |attrs|
          attrs[:request_kind] = attrs[:request_kind].presence_in(REQUEST_KINDS) || "other"
          attrs[:name] = attrs[:name].to_s.strip
          attrs[:email] = attrs[:email].to_s.strip.downcase.presence
          attrs[:phone] = attrs[:phone].to_s.strip.presence
          attrs[:city] = attrs[:city].to_s.strip.presence
          attrs[:country_code] = attrs[:country_code].to_s.upcase.presence_in(LocationSearch::COUNTRY_CODES)
          attrs[:latitude] = attrs[:latitude].to_s.strip.presence
          attrs[:longitude] = attrs[:longitude].to_s.strip.presence
          attrs[:location_ref] = attrs[:location_ref].to_s.strip.presence
          attrs[:message] = attrs[:message].to_s.strip
        end
      end

      def request_title(kind)
        {
          "group_path" => "Richiesta per un percorso di gruppo Corpo e Coscienza",
          "individual_treatment" => "Richiesta per un trattamento individuale Corpo e Coscienza",
          "events" => "Richiesta sugli eventi Corpo e Coscienza",
          "information" => "Richiesta informazioni su Corpo e Coscienza",
          "training" => "Richiesta informazioni sulla formazione",
          "find_professional" => "Richiesta di un professionista Corpo e Coscienza",
          "professional_application" => "Candidatura di un professionista formato",
          "other" => "Richiesta dal sito Corpo e Coscienza"
        }.fetch(kind)
      end

      def decimal_or_nil(value)
        Float(value, exception: false)
      end
  end
end
