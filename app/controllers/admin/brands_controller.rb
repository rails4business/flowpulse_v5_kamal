module Admin
  class BrandsController < BaseController
    dashboard_section :brands

    before_action :require_superadmin!
    before_action :set_node, only: :show

    def index
      @active_tab = params[:tab].presence_in(%w[brands domains building]) || "brands"

      if @active_tab == "domains"
        @domains = Domain.includes(:node, :role_assignment).order(:hostname)
      elsif @active_tab == "building"
        container = Node.find_by(slug: "brand-in-costruzione")
        @brands = container ? container.children.preload(:domains, :role_assignment, :parent).order(:title, :id) : Node.none
        @brand_previews = load_building_previews
      else
        @brands = Node.joins(:domains)
          .distinct
          .preload(:domains, :role_assignment, :parent)
          .order(:title, :id)
      end
    end

    def show
      @active_tab = params[:tab].presence_in(%w[tree info calendars services processes material]) || "tree"
      @children = @node.children.includes(:domains, :link_node, :role_assignment).order(:position, :title)
      @domains = @node.domains.order(:hostname)
      @ancestors = @node.ancestors.order(:depth, :position, :title)
      @tree_nodes = @node.self_and_descendants.includes(:domains, :link_node, :role_assignment, :professional_owner_node).order(:position, :title, :id).to_a
      @tree_nodes_by_parent_id = @tree_nodes.group_by(&:parent_id)
      @services = @node.services.order(:title) if @active_tab == "services"
      if @active_tab == "calendars"
        owned = @node.professional? ? @node.professional_calendars.includes(:context_node).to_a : []
        contextual = @node.context_professional_calendars.includes(:professional_node).to_a
        @professional_calendars = (owned + contextual).uniq.sort_by do |calendar|
          [calendar.professional_node.title, calendar.context_node.title, calendar.title]
        end
        @calendar_context_nodes = Node.order(:title) if @node.professional?
      end
      @brand_processes = @node.brand_processes.includes(:data_experiences).order(:title) if @active_tab == "processes"
      load_editorial_material if @active_tab == "material"
    end

    private

    def set_node
      @node = Node.includes(:domains, :link_node, :role_assignment, :parent).find(params[:id])
    end

    def load_editorial_material
      registry = BrandEditorial::Repository.new.load(@node.slug)
      return unless registry.editorial.fetch("owner_node_slug") == @node.slug

      @editorial_entries = BrandEditorial::Repository.new.entries(@node.slug, include_non_public: true)
    rescue Editorial::SourceNotFoundError
      @editorial_entries = nil
    end

    def load_building_previews
      path = Rails.root.join("config/data/generaimpresa/brands_in_costruzione.yml")
      data = YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
      data.fetch("brands", {}).each_value.index_by { |entry| entry.fetch("node_slug") }
    end
  end
end
