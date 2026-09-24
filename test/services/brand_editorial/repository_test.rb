require "test_helper"

module BrandEditorial
  class RepositoryTest < ActiveSupport::TestCase
    test "censisce il materiale editoriale PosturaCorretta, incluso il primo libro migrato" do
      repository = Repository.new
      brand = repository.load("posturacorretta")

      assert_equal "posturacorretta", brand.editorial.fetch("owner_node_slug")
      assert_includes repository.keys, "posturacorretta"
      assert_equal 9, repository.entries("posturacorretta").size
      assert_equal 12, repository.entries("posturacorretta", include_non_public: true).size
      assert_equal "mappa-percorsi-storica", repository.entries("posturacorretta", include_non_public: true).last.fetch("id")
    end

    test "risolve solo sorgenti esistenti sotto config data" do
      repository = Repository.new
      course_catalog = repository.entries("posturacorretta").find { |entry| entry.fetch("id") == "corsi-e-capitoli" }

      assert_equal Rails.root.join("config/data/posturacorretta/contenuti/contents.yml"), repository.source_path(course_catalog)
      assert_raises(Editorial::InvalidKeyError) { repository.load("../posturacorretta") }
    end
  end
end
