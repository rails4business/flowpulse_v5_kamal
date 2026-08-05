module Admin
  class ContentTaxonomyController < BaseController
    dashboard_section :content_taxonomy
    before_action :require_superadmin!

    def show
      @taxonomy = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/contenuti/tassonomia.yml"), permitted_classes: [], aliases: false) || {}
      @catalog = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/contenuti/catalog.yml"), permitted_classes: [], aliases: false) || {}
      @article_count = @catalog.values.sum { |category| category.fetch("articles", []).size }
    end
  end
end
