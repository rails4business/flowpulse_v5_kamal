module Brands
  module Rails4business
    class ReusableSkillsController < ApplicationController
      layout "landing"

      before_action :set_skill, only: %i[show update]

      def index
        @skills_by_status = skills.includes(:nodes).recent_first.group_by(&:status)
        @skill = skills.new
      end

      def show
        load_options
      end

      def create
        @skill = skills.new(skill_params)
        @skill.responsible_profile ||= current_profile

        if @skill.save
          redirect_to rails4b_skill_path(@skill), notice: "Skill aggiunta a Rails4Business."
        else
          @skills_by_status = skills.includes(:nodes).recent_first.group_by(&:status)
          render :index, status: :unprocessable_entity
        end
      end

      def update
        if @skill.update(skill_params)
          redirect_to rails4b_skill_path(@skill), notice: "Skill aggiornata."
        else
          load_options
          render :show, status: :unprocessable_entity
        end
      end

      private

        def skills
          current_profile.reusable_skills
        end

        def set_skill
          @skill = skills.find(params[:id])
        end

        def load_options
          @node_options = available_commitment_nodes
          @problem_options = current_profile.problem_solving_cycles.order(:title)
        end

        def skill_params
          params.require(:reusable_skill).permit(
            :title, :slug, :category, :status, :description, :purpose,
            :operation_notes, :reuse_notes, node_ids: [], problem_solving_cycle_ids: []
          )
        end
    end
  end
end
