module CreatorWorld
  class ContentsController < BaseController
    layout "flowtree_editor"

    before_action :set_role_assignment
    before_action :set_node
    before_action :set_content

    def edit
      prepare_editor
    end

    def update
      @content.assign_attributes(content_params)
      @content.save!

      synchronizer = ContentEditing::BodySynchronizer.new(@content)
      case params[:sync_action]
      when "save_markdown"
        synchronizer.import_markdown!(params.dig(:content, :body_md).to_s)
      when "save_lexxy"
        synchronizer.import_lexxy!(params.dig(:content, :body).to_s)
      when "resolve_markdown"
        synchronizer.resolve_with_markdown!(params.dig(:content, :body_md).to_s)
      when "resolve_lexxy"
        synchronizer.resolve_with_lexxy!(params.dig(:content, :body).to_s)
      end

      redirect_to edit_creator_world_role_assignment_node_content_path(@role_assignment, @node, @content),
        notice: content_notice
    rescue ActiveRecord::RecordInvalid
      prepare_editor
      render :edit, status: :unprocessable_entity
    end

    private

      def set_role_assignment
        @role_assignment = if superadmin?
          RoleAssignment.find_by!(id: params[:role_assignment_id], role: :ideatore)
        else
          Current.user.role_assignments.find_by!(id: params[:role_assignment_id], role: :ideatore)
        end
      end

      def set_node
        @node = @role_assignment.nodes.find(params[:node_id])
      end

      def set_content
        direct = @node.editorial_contents
        linked = Content.where(id: @node.outgoing_content_links.select(:target_content_id))
        @content = direct.or(linked).find(params[:id])
      end

      def prepare_editor
        @root = @node.root
        @tree = @role_assignment.nodes.hash_tree
        @breadcrumbs = @node.self_and_ancestors.reverse
        @content.body = NodeContent::MarkdownToHtml.call(@content.body_md) if @content.body.blank? && @content.body_md.present?
        @publication_choices = @content.publications.order(:position, :id)
      end

      def content_params
        params.require(:content).permit(
          :title, :description, :role, :placement, :position, :show_publication_id,
          :publication_status, :publication_visibility
        )
      end

      def content_notice
        @content.sync_status == "conflict" ? "Contenuto salvato: il conflitto Markdown/Lexxy richiede una scelta." : "Contenuto aggiornato."
      end
  end
end
