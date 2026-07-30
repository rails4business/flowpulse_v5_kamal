class GeneraImpresaCatalog
  PATH = Rails.root.join("config/data/generaimpresa/brands.yml")
  PROJECTS_PATH = Rails.root.join("config/data/generaimpresa/projects.yml")

  attr_reader :site, :brands, :projects

  def self.load
    new
  end

  def initialize
    data = YAML.safe_load_file(PATH, permitted_classes: [], aliases: false) || {}
    @site = data.fetch("site", {})
    posturacorretta_projects = PosturacorrettaProjectCatalog.load.fetch("projects", []).each { |project| project["source"] ||= "posturacorretta" }
    genera_impresa_data = YAML.safe_load_file(PROJECTS_PATH, permitted_classes: [], aliases: false) || {}
    @projects = posturacorretta_projects + genera_impresa_data.fetch("projects", [])
    @brands = assign_projects(data.fetch("brands", []))
  end

  def brand(slug)
    brands.find { |item| item["slug"] == slug }
  end

  def project(slug)
    projects.find { |item| item["slug"] == slug }
  end

  def brand_for_project(project)
    brands.find { |brand| brand.fetch("projects", []).any? { |item| item["slug"] == project["slug"] } }
  end

  private

  def assign_projects(configured_brands)
    default_brand = configured_brands.find { |brand| brand["default"] }

    configured_brands.each do |brand|
      explicit_slugs = brand.fetch("project_slugs", [])
      brand["projects"] = projects.select { |project| explicit_slugs.include?(project["slug"]) }
    end

    assigned_slugs = configured_brands.flat_map { |brand| brand.fetch("projects", []).map { |project| project["slug"] } }
    if default_brand
      excluded = default_brand.fetch("exclude_project_slugs", [])
      default_brand["projects"] = projects.reject { |project| assigned_slugs.include?(project["slug"]) || excluded.include?(project["slug"]) }
    end

    configured_brands
  end
end
