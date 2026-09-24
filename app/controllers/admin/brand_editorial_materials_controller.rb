module Admin
  class BrandEditorialMaterialsController < BaseController
    before_action :require_superadmin!
    before_action :set_brand

    def show
      registry = BrandEditorial::Repository.new.load(@brand.slug)
      raise ActiveRecord::RecordNotFound unless registry.editorial.fetch("owner_node_slug") == @brand.slug

      @entry = registry.entries.find { |candidate| candidate["id"] == params[:entry_id].to_s }
      raise ActiveRecord::RecordNotFound unless @entry

      @source_path = BrandEditorial::Repository.new.source_path(@entry)
      @source_content = @source_path.file? ? @source_path.read : nil
    rescue Editorial::SourceNotFoundError, Editorial::InvalidKeyError
      raise ActiveRecord::RecordNotFound
    end

    private

    def set_brand
      @brand = Node.find(params[:brand_id])
    end
  end
end
