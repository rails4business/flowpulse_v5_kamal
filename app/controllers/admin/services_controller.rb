module Admin
  class ServicesController < BaseController
    before_action :require_superadmin!
    before_action :set_node
    before_action :set_service, only: %i[update destroy]

    def create
      service = @node.services.new(service_params.merge(created_by_user: Current.user))
      if service.save
        redirect_to admin_brand_path(@node, tab: "services"), notice: "Servizio aggiunto."
      else
        redirect_to admin_brand_path(@node, tab: "services"), alert: service.errors.full_messages.to_sentence
      end
    end

    def update
      if @service.update(service_params)
        redirect_to admin_brand_path(@node, tab: "services"), notice: "Servizio aggiornato."
      else
        redirect_to admin_brand_path(@node, tab: "services"), alert: @service.errors.full_messages.to_sentence
      end
    end

    def destroy
      @service.destroy!
      redirect_to admin_brand_path(@node, tab: "services"), notice: "Servizio rimosso."
    rescue ActiveRecord::RecordNotDestroyed
      redirect_to admin_brand_path(@node, tab: "services"), alert: "Il servizio è già utilizzato da una Sessione. Puoi disattivarlo."
    end

    private

      def set_node
        @node = Node.find(params[:brand_id])
      end

      def set_service
        @service = @node.services.find(params[:id])
      end

      def service_params
        params.require(:service).permit(:title, :slug, :description, :active)
      end
  end
end
