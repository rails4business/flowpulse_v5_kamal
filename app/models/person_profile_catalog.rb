class PersonProfileCatalog
  PATH = Rails.root.join("config/data/people/profiles.yml")

  def self.all
    data = YAML.safe_load_file(PATH, permitted_classes: [], aliases: false) || {}
    data.fetch("profiles", []).index_by { |profile| profile.fetch("slug") }
  end

  def self.find(slug)
    all[slug.to_s]
  end
end
