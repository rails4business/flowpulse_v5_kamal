require "test_helper"

module Editorial
  class SiteRepositoryTest < ActiveSupport::TestCase
    test "loads the MarkPostura pilot without using arbitrary paths" do
      repository = SiteRepository.new
      site = repository.load("markpostura_it")
      page = repository.page(site, "home")

      assert_equal "markpostura_it", site.key
      assert_equal "markpostura", site.site.fetch("node_slug")
      assert_equal "/", site.mount("home").fetch("path")
      assert_equal "home", page.fetch("page").fetch("key")
      assert_equal "public", page.fetch("page").fetch("visibility")
      assert_equal %w[home timeline], repository.page_keys(site)
    end

    test "rejects unsafe keys" do
      repository = SiteRepository.new

      assert_raises(InvalidKeyError) { repository.load("../markpostura_it") }
      assert_raises(InvalidKeyError) { repository.page(repository.load("markpostura_it"), "../../home") }
    end
  end
end
