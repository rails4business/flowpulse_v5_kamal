module Brands
  module Impegno
    class ExperiencesController < ExperienceBaseController
      before_action :set_experience, only: %i[show update]
      before_action :ensure_experience_access!, only: %i[show update]

      def index
        @experiences = DataExperience.includes(brand_process: :node).order(updated_at: :desc)
      end

      def new
        @experience = DataExperience.new
        load_processes
      end

      def create
        @experience = DataExperience.new(experience_params.merge(created_by_user: Current.user))
        if @experience.save
          redirect_to impegno_experience_path(@experience), notice: "Esperienza creata."
        else
          load_processes
          render :new, status: :unprocessable_entity
        end
      end

      def show
        prepare_workbench_state
      end

      def update
        if @experience.update(experience_params)
          respond_with_workbench(notice: "Esperienza aggiornata.")
        else
          respond_with_workbench(alert: @experience.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      private

        def experience_params
          params.require(:data_experience).permit(:title, :description, :brand_process_id)
        end

        def load_processes
          @brand_processes = BrandProcess.includes(:node).where(status: %w[draft active]).order("nodes.title", :title)
        end
    end
  end
end
