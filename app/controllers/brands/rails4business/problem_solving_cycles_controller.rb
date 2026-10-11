module Brands
  module Rails4business
    class ProblemSolvingCyclesController < ApplicationController
      layout "landing"

      before_action :set_cycle, only: %i[show update]

      def index
        load_cycles
        @cycle = cycles.new
      end

      def show
        @steps = ProblemSolvingCycle::STEPS
        @node_options = available_commitment_nodes
      end

      def create
        @cycle = cycles.new(cycle_params)
        @cycle.responsible_profile ||= current_profile
        @cycle.status = cycles.where(status: "active").exists? ? "backlog" : "active"

        if @cycle.save
          redirect_to rails4b_problem_path(@cycle), notice: "Problema aggiunto al metodo di lavoro."
        else
          load_cycles
          render :index, status: :unprocessable_entity
        end
      end

      def update
        if params[:operation].present?
          apply_operation!
          redirect_to rails4b_problem_path(@cycle), notice: operation_notice
        elsif @cycle.update(cycle_params)
          redirect_to rails4b_problem_path(@cycle), notice: "Scheda aggiornata."
        else
          @steps = ProblemSolvingCycle::STEPS
          @node_options = available_commitment_nodes
          render :show, status: :unprocessable_entity
        end
      end

      private

        def cycles
          current_profile.problem_solving_cycles
        end

        def set_cycle
          @cycle = cycles.find(params[:id])
        end

        def load_cycles
          records = cycles.includes(:nodes).recent_first
          @active_cycle = records.find(&:active?)
          @backlog_cycles = records.select { |cycle| cycle.status == "backlog" }
          @resolved_cycles = records.select { |cycle| cycle.status == "resolved" }
          @closed_cycles = records.select { |cycle| cycle.status == "closed" }
          @steps = ProblemSolvingCycle::STEPS
        end

        def cycle_params
          params.require(:problem_solving_cycle).permit(
            :title, :problem, :isolated_problem, :possible_solutions, :minimum_solution,
            :self_test, :small_group_test, :feedback, :validation_notes,
            :diffusion_notes, :closure_notes, node_ids: []
          )
        end

        def apply_operation!
          case params[:operation]
          when "focus"
            ProblemSolvingCycle.transaction do
              cycles.where(status: "active").where.not(id: @cycle.id).update_all(status: "backlog", updated_at: Time.current)
              @cycle.update!(status: "active", resolved_at: nil)
            end
          when "advance"
            @cycle.update!(current_step: [@cycle.current_step + 1, ProblemSolvingCycle::STEPS.size].min)
          when "back"
            @cycle.update!(current_step: [@cycle.current_step - 1, 0].max)
          when "resolve"
            raise ActionController::BadRequest, "Completa tutti i passaggi prima di chiudere il ciclo" unless @cycle.current_step == ProblemSolvingCycle::STEPS.size

            @cycle.update!(status: "resolved", resolved_at: Time.current)
          when "close"
            @cycle.update!(status: "closed")
          when "reopen"
            @cycle.update!(status: "backlog", resolved_at: nil)
          else
            raise ActionController::BadRequest, "Operazione non valida"
          end
        end

        def operation_notice
          { "focus" => "Problema messo a fuoco.", "advance" => "Passaggio completato.",
            "back" => "Passaggio riaperto.", "resolve" => "Soluzione verificata e ciclo risolto.",
            "close" => "Ciclo chiuso.", "reopen" => "Ciclo riaperto." }.fetch(params[:operation])
        end
    end
  end
end
