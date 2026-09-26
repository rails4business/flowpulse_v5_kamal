require "test_helper"

class ChangelogRepositoryTest < ActiveSupport::TestCase
  test "loads the entries of one Brand newest first" do
    repository = ChangelogRepository.new(brand: "impegno")

    entries = repository.entries

    assert entries.any?
    assert_equal entries.map { |entry| entry.fetch("date_value") }.sort.reverse,
      entries.map { |entry| entry.fetch("date_value") }
    assert entries.all? { |entry| entry.fetch("body").present? }
    assert entries.all? { |entry| entry.fetch("source_path").start_with?("config/data/brands/impegno/changelog/") }
  end

  test "resolves a changelog from its canonical or alias host" do
    assert_equal "posturacorretta", ChangelogRepository.for_host("www.posturacorretta.org").brand_key
    assert_equal "impegno", ChangelogRepository.for_host("impegno.it").brand_key
  end

  test "catalog keeps each Brand autonomous" do
    catalog = ChangelogRepository.catalog

    assert_equal "rails4b.com", catalog.fetch("rails4business").fetch("canonical_host")
    assert_equal 2, catalog.fetch("impegno").fetch("entry_count")
    assert_equal 4, catalog.fetch("posturacorretta").fetch("entry_count")
    assert catalog.values.all? { |brand| brand.fetch("entry_count").positive? }
    assert_equal %w[cantachetipassa flowpulse generaimpresa igieneposturale ilgiardinodelcorpo impegno markpostura percorso-integrato posturacorretta radioestesia rails4business svuotamente], catalog.keys
  end

  test "rejects an unknown Brand" do
    assert_raises(ArgumentError) { ChangelogRepository.new(brand: "sconosciuto") }
  end
end
