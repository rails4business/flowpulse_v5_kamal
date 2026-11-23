require "test_helper"

class ContentPublishedOnTest < ActiveSupport::TestCase
  setup do
    node = create_catalog_test_node("date-pubblicazione")
    @draft = Content.create!(node:, key: "bozza-con-data", slug: "bozza-con-data", format: "post", title: "Bozza")
    @undated = Content.create!(node:, key: "bozza-senza-data", slug: "bozza-senza-data", format: "post", title: "Senza data")
    @archived = Content.create!(node:, key: "archiviato", slug: "archiviato", format: "post", title: "Archiviato", publication_status: "archived")
    @file = Tempfile.new([ "published_on", ".yml" ])
    @file.write({ "bozza-con-data" => "2026-09-12", "archiviato" => "2026-08-21" }.to_yaml)
    @file.flush
  end

  teardown { @file&.close! }

  test "drafts with a date become public with that date, the others stay as they are" do
    result = ContentPublishedOn.new(path: @file.path).publish!

    assert_equal 1, result.published
    assert_includes result.missing, "bozza-senza-data"
    assert @draft.reload.published_for_public?
    assert_equal Date.new(2026, 9, 12), @draft.published_at.to_date
    assert_equal "draft", @undated.reload.publication_status
    assert_equal "archived", @archived.reload.publication_status
  end

  test "a dry run changes nothing" do
    assert_equal 1, ContentPublishedOn.new(path: @file.path).publish!(dry_run: true).published
    assert_equal "draft", @draft.reload.publication_status
  end
end
