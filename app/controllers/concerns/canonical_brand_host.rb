module CanonicalBrandHost
  extend ActiveSupport::Concern

  BRAND_PATH_HOSTS = {
    "flowpulse" => "flowpulse.net",
    "markpostura" => "markpostura.it",
    "posturacorretta" => "posturacorretta.org",
    "percorso-integrato" => "percorsointegrato.it",
    "generaimpresa" => "generaimpresa.it",
    "rails4b" => "rails4b.com",
    "cantachetipassa" => "cantachetipassa.it",
    "impegno" => "1impegno.it",
    "impegni" => "1impegno.it",
    "igieneposturale" => "igieneposturale.it",
    "il-giardino-del-corpo" => "ilgiardinodelcorpo.it",
    "giardino-del-corpo" => "ilgiardinodelcorpo.it",
    "corpo-e-coscienza" => "corpoecoscienza.org"
  }.freeze

  DEDICATED_BRAND_HOSTS = (BRAND_PATH_HOSTS.values + %w[markpostura.com]).uniq.freeze

  included do
    before_action :use_canonical_brand_host
  end

  private

    def use_canonical_brand_host
      return if local_request?
      return unless dedicated_brand_host?
      return if impegno_service_for_current_brand?

      canonical_host = canonical_brand_host_for_path
      return if canonical_host.blank?
      return if Domain.normalize_host(request.host) == canonical_host

      if request.get? || request.head?
        redirect_to "#{request.protocol}#{canonical_host}#{request.fullpath}",
          status: :moved_permanently,
          allow_other_host: true
      else
        head :not_found
      end
    end

    def dedicated_brand_host?
      host = Domain.normalize_host(request.host).sub(/\Awww\./, "")
      DEDICATED_BRAND_HOSTS.include?(host)
    end

    def canonical_brand_host_for_path
      segments = request.path.to_s.split("/").reject(&:blank?)
      BRAND_PATH_HOSTS[segments.first]
    end

    # 1Impegno è anche un servizio usato all'interno degli altri Brand. In quel
    # caso agenda e mutazioni devono restare sul dominio chiamante, così la
    # Session e il BrandAccess continuano a riferirsi al Brand che sta usando
    # lo strumento. Solo la visita autonoma a /impegno appartiene a 1impegno.it.
    def impegno_service_for_current_brand?
      return false unless controller_path.in?(%w[brands/impegno/home brands/impegno/commitments])

      domain = current_domain&.canonical_domain_record
      return false if domain.blank?

      # Le azioni operative sono una funzione condivisa: il dominio corrente
      # resta il perimetro di accesso anche quando l'URL tecnico usa /impegno
      # o /impegni. Sul dominio proprio di 1Impegno non serve alcuna eccezione.
      if controller_path == "brands/impegno/commitments"
        return Domain.normalize_host(domain.hostname) != "1impegno.it"
      end

      requested_brand = params[:default_brand].presence ||
        params[:context_brand].presence ||
        params[:brand].presence ||
        commitment_brand_context
      return false if requested_brand.blank?

      hostname_brand = BRAND_PATH_HOSTS.key(Domain.normalize_host(domain.hostname))
      current_brand_keys = [domain.auth_slug, domain.site_key, domain.node&.slug, hostname_brand].compact
      current_brand_keys.any? { |key| normalize_brand_context(key) == normalize_brand_context(requested_brand) }
    end

    def commitment_brand_context
      return if params[:id].blank?

      commitment = Brands::Impegno::Commitment.includes(domain: :node).find_by(id: params[:id])
      domain = commitment&.domain&.canonical_domain_record
      domain&.auth_slug.presence || domain&.site_key.presence || domain&.node&.slug
    end

    def normalize_brand_context(value)
      value.to_s.downcase.tr("_", "-")
    end
end
