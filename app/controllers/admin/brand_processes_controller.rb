module Admin
  class BrandProcessesController < BaseController
    before_action :require_superadmin!
    before_action :set_brand
    before_action :set_process, only: %i[update destroy]

    def create
      process_record = @brand.brand_processes.new(process_params.merge(created_by_user: Current.user))
      if process_record.save
        redirect_to admin_brand_path(@brand, tab: "processes"), notice: "Processo aggiunto."
      else
        redirect_to admin_brand_path(@brand, tab: "processes"), alert: process_record.errors.full_messages.to_sentence
      end
    end

    def update
      if @process_record.update(process_params)
        redirect_to admin_brand_path(@brand, tab: "processes"), notice: "Processo aggiornato."
      else
        redirect_to admin_brand_path(@brand, tab: "processes"), alert: @process_record.errors.full_messages.to_sentence
      end
    end

    def destroy
      @process_record.destroy!
      redirect_to admin_brand_path(@brand, tab: "processes"), notice: "Processo rimosso. Le Esperienze collegate sono state conservate."
    end

    private

      def set_brand
        @brand = Node.find(params[:brand_id])
      end

      def set_process
        @process_record = @brand.brand_processes.find(params[:id])
      end

      def process_params
        params.require(:brand_process).permit(:title, :slug, :description, :status)
      end
  end
end
