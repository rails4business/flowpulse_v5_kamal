module Brands
  class PosturacorrettaController < ::PosturacorrettaController
    def home
      @home_data = YAML.safe_load_file(
        Rails.root.join("config/data/posturacorretta/home/home.yml"),
        permitted_classes: [],
        aliases: false
      ) || {}
      @audiences = YAML.safe_load_file(
        Rails.root.join("config/data/posturacorretta/shared/audiences.yml"),
        permitted_classes: [],
        aliases: false
      ) || {}
      @posturacorretta_taxonomies = PosturacorrettaTaxonomies.load
      render "landing/posturacorretta"
    end
  end
end
