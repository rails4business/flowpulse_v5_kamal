module Brands
  module Impegno
    class ProblemsController < ApplicationController
      layout "landing"

      STEPS = [
        ["identify", "Definisci chiaramente il problema"],
        ["isolate", "Isola il problema"],
        ["simple_solution", "Trova la soluzione più semplice"],
        ["self_test", "Provala su di te"],
        ["small_group_test", "Provala con poche persone"],
        ["validate", "Verifica la soluzione"],
        ["share", "Diffondila a chi ha lo stesso problema"]
      ].freeze
      PROBLEM_KINDS = %w[problem_solving work_commitment].freeze

      def index
        load_problems
        render layout: false if params[:workspace] == "1"
      end

      def create
        commitment = problems.build(
          kind: "problem_solving",
          title: problem_params[:title], description: problem_params[:description],
          created_by_profile: current_profile, domain: impegno_domain,
          status: problem_status, blocks_calendar: false, pricing_type: "none",
          contribution_type: "unpaid", metadata: problem_metadata
        )
        if commitment.save
          redirect_to impegno_path(area: "problems"), notice: "Problema aggiunto."
        else
          load_problems
          @problem_errors = commitment.errors.full_messages
          render :index, status: :unprocessable_entity
        end
      end

      def update
        problem = problems.find(params[:id])
        case params[:operation]
        when "focus" then focus!(problem)
        when "advance" then advance!(problem)
        when "resolve" then resolve!(problem)
        when "reopen" then focus!(problem)
        else raise ActionController::BadRequest, "Operazione non valida"
        end
        redirect_to impegno_path(area: "problems")
      end

      private

        def problems
          current_profile.data_commitments.where(kind: PROBLEM_KINDS)
        end

        def load_problems
          records = problems.order(updated_at: :desc).to_a
          @steps = STEPS
          @active_problem = records.find { |item| item.metadata["attention_state"] == "active" }
          @future_problems = records.select { |item| item.metadata["attention_state"] == "future" }
          @resolved_problems = records.select { |item| item.metadata["attention_state"] == "resolved" }
        end

        def problem_params
          params.require(:problem).permit(:title, :description)
        end

        def problem_metadata
          { "attention_state" => problems.where("metadata ->> 'attention_state' = ?", "active").exists? ? "future" : "active", "completed_steps" => [] }
        end

        def problem_status
          problems.where("metadata ->> 'attention_state' = ?", "active").exists? ? "planned" : "in_progress"
        end

        def focus!(problem)
          Brands::Impegno::Commitment.transaction do
            problems.where("metadata ->> 'attention_state' = ?", "active").where.not(id: problem.id).find_each do |other|
              other.update!(metadata: other.metadata.merge("attention_state" => "future"), status: "planned", resolved_at: nil)
            end
            problem.update!(metadata: problem.metadata.merge("attention_state" => "active"), status: "in_progress", resolved_at: nil)
          end
        end

        def advance!(problem)
          raise ActionController::BadRequest, "Il problema non è attivo" unless problem.metadata["attention_state"] == "active"

          completed = Array(problem.metadata["completed_steps"])
          next_key = STEPS.map(&:first).find { |key| !completed.include?(key) }
          completed << next_key if next_key
          problem.update!(metadata: problem.metadata.merge("completed_steps" => completed))
        end

        def resolve!(problem)
          completed = Array(problem.metadata["completed_steps"])
          raise ActionController::BadRequest, "Completa tutti i passaggi prima di risolvere il problema" unless STEPS.map(&:first).all? { |key| completed.include?(key) }

          problem.update!(metadata: problem.metadata.merge("attention_state" => "resolved"), status: "completed", resolved_at: Time.current)
        end

        def impegno_domain
          Domain.active.find_by(hostname: ["1impegno.it", "impegno.it"]) || Domain.active.where(primary: true).first || Domain.active.first!
        end
    end
  end
end
