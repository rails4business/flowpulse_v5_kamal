require "test_helper"

class LocationSearchTest < ActiveSupport::TestCase
  test "normalizes a Photon feature without exposing the provider format" do
    search = LocationSearch.new(query: "Brescia", country_code: "IT", language: "it")
    feature = {
      "properties" => {
        "name" => "Brescia", "county" => "Brescia", "state" => "Lombardia", "country" => "Italia",
        "countrycode" => "IT", "osm_type" => "R", "osm_id" => 44881
      },
      "geometry" => { "coordinates" => [10.2118, 45.5416] }
    }

    result = search.send(:normalize, feature)

    assert_equal "Brescia, Lombardia, Italia", result[:label]
    assert_equal 45.5416, result[:latitude]
    assert_equal 10.2118, result[:longitude]
    assert_equal "osm:R:44881", result[:location_ref]
  end

  test "defaults an unsupported country and language to Italian" do
    search = LocationSearch.new(query: "Roma", country_code: "invalid", language: "invalid")

    assert_equal "IT", search.send(:country_code)
    assert_equal "it", search.send(:language)
  end

  test "normalizes an Open Meteo result" do
    search = LocationSearch.new(query: "Calvisano", country_code: "IT", language: "it")
    result = search.send(:normalize_open_meteo, {
      "id" => 3181258, "name" => "Calvisano", "latitude" => 45.35, "longitude" => 10.34,
      "admin2" => "Brescia", "admin1" => "Lombardia", "country" => "Italia", "country_code" => "IT"
    })

    assert_equal "Calvisano, Brescia, Lombardia, Italia", result[:label]
    assert_equal "geonames:3181258", result[:location_ref]
  end
end
