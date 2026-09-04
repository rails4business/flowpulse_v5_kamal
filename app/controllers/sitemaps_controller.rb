class SitemapsController < ApplicationController
  allow_unauthenticated_access
  layout false

  def show
    @urls = core_urls + published_article_urls

    respond_to do |format|
      format.xml
    end
  end

  private
    def core_urls
      %w[
        /
        /posturacorretta
        /posturacorretta/contenuti
        /posturacorretta/metodiche
        /posturacorretta/accademia
        /posturacorretta/guida
        /posturacorretta/primo-mese
        /posturacorretta/insegnanti
        /posturacorretta/percorsi-sul-territorio
        /posturacorretta/eventi
      ].map { |path| { loc: absolute_url(path) } }
    end

    def published_article_urls
      catalog_path = Rails.root.join("config/data/posturacorretta/contenuti/catalog.yml")
      catalog = YAML.safe_load_file(catalog_path, permitted_classes: [], aliases: false) || {}

      catalog.values.flat_map { |category| category.fetch("articles", []) }.filter_map do |article|
        slug = article["slug"].to_s
        source = article["source"].to_s
        next if slug.blank? || !source.start_with?("articoli/")

        publication_date = publication_date_for(source)
        next if publication_date && publication_date > Date.current

        { loc: absolute_url("/posturacorretta/contenuti/#{slug}"), lastmod: publication_date }
      end.uniq { |entry| entry[:loc] }
    end

    def publication_date_for(source)
      match = File.basename(source).match(/\A(\d{4}-\d{2}-\d{2})-/)
      Date.iso8601(match[1]) if match
    rescue ArgumentError
      nil
    end

    def absolute_url(path)
      "https://posturacorretta.org#{path}"
    end
end
