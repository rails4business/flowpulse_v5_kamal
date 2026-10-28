module Flowpulse
  class NetworkController < ApplicationController
    layout "landing"
    allow_unauthenticated_access only: :global

    def global
      @network_nodes = Node.published_public
        .includes(:parent, :children, :link_node, :professional_owner_node, :domains)
        .order(:title, :id)
      @manageable_role_assignment_ids = if Current.user&.superadmin_user?
        @network_nodes.map(&:role_assignment_id).uniq
      else
        Current.user&.role_assignments&.ideatore&.pluck(:id) || []
      end
    end

    def destroy_node
      node = Node.find(params[:id])
      unless can_manage_node?(node)
        return redirect_to flowpulse_global_network_path(node: node.slug, vista: params[:vista]), alert: "Non hai i permessi per eliminare questo Node."
      end
      if node.domains.exists?
        return redirect_to flowpulse_global_network_path(node: node.slug, vista: params[:vista]), alert: "Un Brand con dominio non può essere eliminato dalla mappa."
      end
      if node.children.exists?
        return redirect_to flowpulse_global_network_path(node: node.slug, vista: params[:vista]), alert: "Prima di eliminare il Node devi ricollocare o eliminare i suoi figli."
      end

      if node.destroy
        redirect_to flowpulse_global_network_path(vista: params[:vista]), notice: "Node #{node.title} eliminato. Ricorda di aggiornare il catalogo YAML."
      else
        redirect_to flowpulse_global_network_path(node: node.slug, vista: params[:vista]), alert: node.errors.full_messages.to_sentence
      end
    rescue ActiveRecord::RecordNotDestroyed => error
      redirect_to flowpulse_global_network_path(node: node&.slug, vista: params[:vista]), alert: error.record.errors.full_messages.to_sentence
    end

    def show
      @professional_brands = professional_brands
      @owned_brands = owned_project_brands
      group_owned_brands
      @administered_brands = contextual_brands_for(%w[admin responsabile]) - @owned_brands
      @collaboration_assignments = collaboration_assignments.reject do |assignment|
        (@owned_brands + @administered_brands).include?(assignment.context)
      end
    end

    private

      def can_manage_node?(node)
        return false if Current.user.blank?
        return true if Current.user.superadmin_user?

        Current.user.role_assignments.ideatore.exists?(id: node.role_assignment_id)
      end

      def professional_brands
        @professional_brands ||= Node.professional.joins(:domains)
          .where("nodes.role_assignment_id IN (?) OR nodes.id = ?", owner_role_assignment_ids, current_profile.primary_node_id)
          .distinct.preload(:domains).order(:title, :id).to_a
      end

      def owned_project_brands
        professional_ids = professional_brands.map(&:id)
        Node.project.joins(:domains)
          .where("nodes.role_assignment_id IN (:role_ids) OR nodes.professional_owner_node_id IN (:professional_ids)",
            role_ids: owner_role_assignment_ids.presence || [0], professional_ids: professional_ids.presence || [0])
          .distinct.preload(:domains).order(:title, :id).to_a
      end

      def contextual_brands_for(roles)
        current_profile.role_assignments.includes(context: :domains)
          .where(role: roles, context_type: "Node")
          .filter_map { |assignment| assignment.context if assignment.context&.brand? }
          .uniq.sort_by { |node| [node.title, node.id] }
      end

      def collaboration_assignments
        current_profile.role_assignments.includes(context: :domains)
          .where(role: :operator, context_type: "Node")
          .select { |assignment| assignment.context&.brand? }
          .sort_by { |assignment| [assignment.context.title, assignment.id] }
      end

      def group_owned_brands
        @owned_brands_by_professional_id = Hash.new { |hash, key| hash[key] = [] }
        @unassigned_owned_brands = []

        @owned_brands.each do |brand|
          professional = @professional_brands.find { |candidate| candidate.id == brand.professional_owner_node_id }
          if professional.blank?
            matching = @professional_brands.select { |candidate| candidate.role_assignment_id == brand.role_assignment_id }
            professional = matching.one? ? matching.first : nil
          end

          if professional
            @owned_brands_by_professional_id[professional.id] << brand
          else
            @unassigned_owned_brands << brand
          end
        end
      end

      def owner_role_assignment_ids
        @owner_role_assignment_ids ||= current_profile.role_assignments.where(role: :ideatore).pluck(:id)
      end
  end
end
