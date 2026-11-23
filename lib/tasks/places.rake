namespace :places do
  desc "Copy posturacorretta_directory_places into Place + PlaceDomain, once per slug; the old table stays (DRY_RUN=1 to preview)"
  task import_directory: :environment do
    dry_run = ENV["DRY_RUN"].present?
    copied = 0
    Brands::Posturacorretta::DirectoryPlace.includes(:domain).find_each do |old|
      next puts("Già presente: #{old.slug}") if Place.exists?(slug: old.slug)

      copied += 1
      next if dry_run

      published = old.visibility == "public"
      Place.transaction do
        place = Place.create!(
          name: old.name, slug: old.slug, city: old.city, address: old.address, description: old.summary,
          publication_status: published ? "published" : "draft", publication_visibility: published ? "public" : "private",
          metadata: old.metadata.merge("kind" => old.kind, "listing_sections" => old.listing_sections)
        )
        place.place_domains.create!(domain: old.domain)
      end
    end
    puts "#{'[prova] ' if dry_run}Luoghi copiati: #{copied}."
  end
end
