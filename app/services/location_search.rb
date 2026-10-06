require "digest"
require "json"
require "net/http"

class LocationSearch
  COUNTRY_CODES = %w[IT FR CH ES DE AT BE NL GB PT].freeze
  PHOTON_URL = ENV.fetch("PHOTON_URL", "https://photon.komoot.io/api").freeze
  OPEN_METEO_URL = ENV.fetch("OPEN_METEO_GEOCODING_URL", "https://geocoding-api.open-meteo.com/v1/search").freeze

  def self.call(query:, country_code: "IT", language: "it")
    new(query:, country_code:, language:).call
  end

  def initialize(query:, country_code:, language:)
    @query = query.to_s.squish
    @country_code = country_code.to_s.upcase.presence_in(COUNTRY_CODES) || "IT"
    @language = language.to_s.downcase.presence_in(%w[it fr de es en pt nl]) || "it"
  end

  def call
    return [] if query.length < 3

    Rails.cache.fetch(cache_key, expires_in: 12.hours) { fetch_locations }
  rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => error
    Rails.logger.warn("Photon location search failed: #{error.class}: #{error.message}")
    []
  end

  private

    attr_reader :query, :country_code, :language

    def cache_key
      digest = Digest::SHA256.hexdigest([query.downcase, country_code, language].join("|"))
      "location-search/v2/#{digest}"
    end

    def fetch_locations
      fetch_open_meteo.presence || fetch_photon
    end

    def fetch_open_meteo
      uri = URI(OPEN_METEO_URL)
      uri.query = URI.encode_www_form(name: query, countryCode: country_code, language: language, count: 6, format: "json")
      payload = request_json(uri, provider: "Open-Meteo")
      payload.fetch("results", []).filter_map { |result| normalize_open_meteo(result) }.uniq { |item| item[:label] }
    rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => error
      Rails.logger.warn("Open-Meteo location search failed: #{error.class}: #{error.message}")
      []
    end

    def fetch_photon
      uri = URI(PHOTON_URL)
      uri.query = URI.encode_www_form(
        q: query,
        countrycode: country_code,
        lang: language,
        limit: 6
      )
      request_json(uri, provider: "Photon").fetch("features", []).filter_map { |feature| normalize(feature) }.uniq { |item| item[:label] }
    rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => error
      Rails.logger.warn("Photon location search failed: #{error.class}: #{error.message}")
      []
    end

    def request_json(uri, provider:)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 1.5, read_timeout: 2.5) do |http|
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "CorpoECoscienza/1.0 (https://corpoecoscienza.org; #{provider})"
        http.request(request)
      end
      return {} unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def normalize_open_meteo(result)
      parts = [result["name"], result["admin2"], result["admin1"], result["country"]].compact_blank.uniq
      return if parts.empty? || result["latitude"].blank? || result["longitude"].blank?

      {
        label: parts.join(", "),
        city: result["name"],
        state: result["admin1"],
        country: result["country"],
        country_code: result["country_code"].to_s.upcase.presence || country_code,
        latitude: result["latitude"],
        longitude: result["longitude"],
        location_ref: result["id"].present? ? "geonames:#{result['id']}" : nil
      }.compact
    end

    def normalize(feature)
      properties = feature.fetch("properties", {})
      coordinates = feature.dig("geometry", "coordinates")
      return unless coordinates.is_a?(Array) && coordinates.size >= 2

      parts = [properties["name"], properties["county"], properties["state"], properties["country"]].compact_blank.uniq
      return if parts.empty?

      {
        label: parts.join(", "),
        city: properties["name"],
        state: properties["state"],
        country: properties["country"],
        country_code: properties["countrycode"].to_s.upcase.presence || country_code,
        latitude: coordinates[1],
        longitude: coordinates[0],
        location_ref: ["osm", properties["osm_type"], properties["osm_id"]].compact.join(":").presence
      }.compact
    end
end
