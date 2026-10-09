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
    "svuotamente" => "svuotamente.it",
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
      return "svuotamente.it" if segments.first(2) == %w[brands svuotamente]

      BRAND_PATH_HOSTS[segments.first]
    end
end
