module Flowpulse
  class NetworkController < ApplicationController
    layout "landing"

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
