module CreatorWorld
  class NodesController < BaseController
    layout :node_layout

    before_action :set_role_assignment
    before_action :set_scoped_node, only: [:tree, :move, :edit, :update, :destroy]

    def index
      @roots = @role_assignment.nodes.roots.order(:position, :title)
      @domains = @role_assignment.domains.order(active: :desc, primary: :desc, hostname: :asc)
      @public_nodes_count = @role_assignment.nodes.published_public.count
      @root_nodes_count = @roots.size
    end

    def tree
      @node.build_content if @node.content.blank?
      @root = @node.root
      @tree = @role_assignment.nodes.hash_tree
      @children = @node.children.order(:position, :title)
      @breadcrumbs = @node.self_and_ancestors.reverse
      @active_tab = params[:tab].presence_in(%w[node content]) || "node"
    end

    def move
      node = @node
      new_parent_id = params[:parent_id].presence
      new_parent = @role_assignment.nodes.find_by(id: new_parent_id) if new_parent_id
      new_position = move_position(node, new_parent)

      if invalid_parent?(node, new_parent_id, new_parent)
        head :unprocessable_entity
        return
      end

      Node.transaction do
        node.role_assignment ||= new_parent&.role_assignment
        node.update!(parent: new_parent)
        node.insert_at(new_position)
      end

      head :ok
    end

    def new
      @parent = @role_assignment.nodes.find_by(id: params[:parent_id]) if params[:parent_id].present?
      @node = @role_assignment.nodes.new(parent: @parent)
      @node.build_content if @node.content.blank?
      @tree = @role_assignment.nodes.hash_tree
      if @parent
        @root = @parent.root
        @breadcrumbs = @parent.self_and_ancestors.reverse
      else
        @root = nil
        @breadcrumbs = []
      end
    end

    def create
      @node = @role_assignment.nodes.new(node_params.merge(role_assignment_id: @role_assignment.id))

      if @node.save
        respond_to do |format|
          format.html { redirect_to tree_creator_world_role_assignment_node_path(@role_assignment, @node), notice: "Nodo creato." }
          format.turbo_stream do
            @root = @node.root
            @tree = @role_assignment.nodes.hash_tree
            @children = @node.children.order(:position, :title)
            @active_tab = "node"
            flash.now[:notice] = "Nodo creato."
            render turbo_stream: [
              turbo_stream.replace("tree_sidebar_content", partial: "creator_world/nodes/tree_view", locals: { tree: @tree, parent_id: @root.parent_id, current_node: @node }),
              turbo_stream.replace("node_workspace", template: "creator_world/nodes/tree"),
              turbo_stream.replace("flowtree_flash_container", partial: "shared/flowtree_editor/flash")
            ]
          end
        end
      else
        @parent = @node.parent
        @tree = @role_assignment.nodes.hash_tree
        if @parent
          @root = @parent.root
          @breadcrumbs = @parent.self_and_ancestors.reverse
        else
          @root = nil
          @breadcrumbs = []
        end
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @node.build_content if @node.content.blank?
      @root = @node.root
      @tree = @role_assignment.nodes.hash_tree
      @breadcrumbs = @node.self_and_ancestors.reverse
    end

    def update
      @node.assign_attributes(node_params)

      if @node.save
        respond_to do |format|
          format.html { redirect_to tree_creator_world_role_assignment_node_path(@role_assignment, @node), notice: "Nodo aggiornato." }
          format.turbo_stream do
            @root = @node.root
            @tree = @role_assignment.nodes.hash_tree
            @children = @node.children.order(:position, :title)
            @active_tab = "node"
            flash.now[:notice] = "Nodo aggiornato."
            render turbo_stream: [
              turbo_stream.replace("tree_sidebar_content", partial: "creator_world/nodes/tree_view", locals: { tree: @tree, parent_id: @root.parent_id, current_node: @node }),
              turbo_stream.replace("node_workspace", template: "creator_world/nodes/tree"),
              turbo_stream.replace("flowtree_flash_container", partial: "shared/flowtree_editor/flash")
            ]
          end
        end
      else
        @root = @node.root
        @tree = @role_assignment.nodes.hash_tree
        @breadcrumbs = @node.self_and_ancestors.reverse
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      root = @node.root
      is_root = (root == @node)

      @node.destroy!

      respond_to do |format|
        format.html { redirect_to after_destroy_path(root), notice: "Nodo eliminato." }
        format.turbo_stream do
          if is_root
            render html: "<script>window.location.href='#{creator_world_role_assignment_nodes_path(@role_assignment)}'</script>".html_safe
          else
            @node = root
            @root = root
            @tree = @role_assignment.nodes.hash_tree
            @children = @node.children.order(:position, :title)
            @active_tab = "node"
            flash.now[:notice] = "Nodo eliminato."
            render turbo_stream: [
              turbo_stream.replace("tree_sidebar_content", partial: "creator_world/nodes/tree_view", locals: { tree: @tree, parent_id: @root.parent_id, current_node: @node }),
              turbo_stream.replace("node_workspace", template: "creator_world/nodes/tree"),
              turbo_stream.replace("flowtree_flash_container", partial: "shared/flowtree_editor/flash")
            ]
          end
        end
      end
    end

    private

    def set_role_assignment
      if superadmin?
        @role_assignment = RoleAssignment.find_by!(id: params[:role_assignment_id], role: :creator_of_worlds)
      else
        @role_assignment = Current.user.role_assignments.find_by!(id: params[:role_assignment_id], role: :creator_of_worlds)
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to dashboard_home_path, alert: "Non hai i permessi per gestire questa configurazione."
    end

    def set_scoped_node
      @node = @role_assignment.nodes.find(params[:id])
    end

    def invalid_parent?(node, parent_id, parent)
      return false if parent_id.blank?
      return true if parent.blank?
      return true if parent.bridge_node?
      return true if node.role_assignment_id.present? &&
        parent.role_assignment_id.present? &&
        node.role_assignment_id != parent.role_assignment_id

      node.self_and_descendants.exists?(id: parent_id)
    end

    def move_position(node, parent)
      return params[:position].to_i unless params[:position] == "last"

      scope = parent ? parent.children : Node.roots.where(role_assignment_id: node.role_assignment_id)
      scope.maximum(:position).to_i + 1
    end

    def after_destroy_path(root)
      return creator_world_role_assignment_nodes_path(@role_assignment) if root == @node

      tree_creator_world_role_assignment_node_path(@role_assignment, root)
    end

    def node_params
      params.require(:node).permit(
        :title,
        :slug,
        :content_type,
        :description,
        :node_type,
        :view_type,
        :status,
        :visibility,
        :parent_id,
        :position,
        :link_node_id,
        content_attributes: [
          :id,
          :editor,
          :format,
          :body_md,
          :body_html,
          :source_path
        ]
      )
    end

    def node_layout
      return "application" if action_name == "index"
      "flowtree_editor"
    end
  end
end
