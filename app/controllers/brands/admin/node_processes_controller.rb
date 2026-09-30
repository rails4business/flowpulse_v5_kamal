module Brands
  module Admin
    class NodeProcessesController < BaseController
      def show
        load_process
        @experiences = @process.data_experiences
          .includes(:data_commitments, data_sessions: [:data_slots, :data_commitments], data_slots: :data_commitments)
          .order(:title, :id)
      end

      def create_experience
        load_process
        experience = @process.data_experiences.new(experience_params.merge(created_by_user: Current.user))
        if experience.save
          redirect_to brand_admin_node_process_path(@brand.slug, @node, @process, anchor: "process-experiences"), notice: "DataExperience aggiunta."
        else
          redirect_to brand_admin_node_process_path(@brand.slug, @node, @process, anchor: "process-experiences"), alert: experience.errors.full_messages.to_sentence
        end
      end

      def update
        load_process
        if @process.update(process_params)
          redirect_to brand_admin_node_process_path(@brand.slug, @node, @process), notice: "Processo aggiornato."
        else
          redirect_to brand_admin_node_process_path(@brand.slug, @node, @process), alert: @process.errors.full_messages.to_sentence
        end
      end

      private

        def load_process
          @node = @brand.self_and_descendants.find(params[:node_id])
          @process = @node.node_processes.find(params[:id])
        end

        def experience_params
          params.require(:data_experience).permit(:title, :description)
        end

        def process_params
          params.require(:node_process).permit(:title, :slug, :description, :status)
        end
    end
  end
end
