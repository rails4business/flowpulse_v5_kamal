module SeoHelper
  FILTERED_LISTING_PATHS = %w[
    /posturacorretta/contenuti
    /posturacorretta/metodiche
  ].freeze

  def seo_filtered_listing?
    meaningful_query_parameters = request.query_parameters.except("tab")
    request.get? && meaningful_query_parameters.present? && FILTERED_LISTING_PATHS.include?(request.path)
  end

  def seo_canonical_url
    return request.original_url unless seo_filtered_listing?

    "#{request.base_url}#{request.path}"
  end

  def seo_noindex?
    seo_filtered_listing?
  end
end
