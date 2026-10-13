module Brands
  module Impegno
    class ProfessionalWorkspaceController < ApplicationController
      layout "landing"

      before_action :require_professional_workspace!

      def show
        @profile = Current.user.profile
        @professional_node = @profile.primary_node if @profile.primary_node&.professional?
        @role_assignments = @profile.role_assignments.includes(:context, :parent).order(:role, :role_operator, :id)
        @operator_assignments = @role_assignments.select(&:operator?)
        @context_nodes = @operator_assignments.filter_map { |assignment| assignment.context if assignment.context.is_a?(Node) }.uniq

        service_nodes = @context_nodes.dup
        if @professional_node
          service_nodes << @professional_node
          service_nodes.concat(@professional_node.professionally_owned_nodes.to_a)
        end
        @service_nodes = service_nodes.uniq.sort_by { |node| [node.title.downcase, node.id] }
        @services = Service.active.includes(:node).where(node: @service_nodes).order("nodes.title", :title)
        @calendars = if @professional_node
                       @professional_node.professional_calendars.active.includes(:context_node).order(:title)
        else
          ProfessionalCalendar.none
        end

        render layout: false if params[:workspace] == "1"
      end

      private

        def require_professional_workspace!
          return if professional_workspace_access?

          redirect_to impegno_path, alert: "Lo spazio Professionista richiede un ruolo operativo o un profilo professionale."
        end

        def professional_workspace_access?
          profile = Current.user&.profile
          return false if profile.blank?

          Current.user.superadmin_user? ||
            profile.primary_node&.professional? ||
            profile.role_assignments.where(role: :operator).exists?
        end
    end
  end
end
