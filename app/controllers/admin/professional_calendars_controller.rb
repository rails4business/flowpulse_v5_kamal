module Admin
  class ProfessionalCalendarsController < BaseController
    before_action :require_superadmin!
    before_action :set_context_node
    before_action :set_calendar, only: %i[update destroy]

    def create
      unless @context_node.professional?
        return redirect_to admin_brand_path(@context_node, tab: "calendars"), alert: "I calendari si creano dal Node professionale."
      end

      calendar = @context_node.professional_calendars.new(calendar_params.merge(created_by_user: Current.user))
      if calendar.save
        redirect_to admin_brand_path(@context_node, tab: "calendars"), notice: "Calendario aggiunto."
      else
        redirect_to admin_brand_path(@context_node, tab: "calendars"), alert: calendar.errors.full_messages.to_sentence
      end
    end

    def update
      if @calendar.update(calendar_params)
        redirect_to admin_brand_path(@context_node, tab: "calendars"), notice: "Calendario aggiornato."
      else
        redirect_to admin_brand_path(@context_node, tab: "calendars"), alert: @calendar.errors.full_messages.to_sentence
      end
    end

    def destroy
      @calendar.destroy!
      redirect_to admin_brand_path(@context_node, tab: "calendars"), notice: "Calendario rimosso."
    rescue ActiveRecord::RecordNotDestroyed
      redirect_to admin_brand_path(@context_node, tab: "calendars"), alert: "Il calendario è già utilizzato da una Sessione. Puoi disattivarlo."
    end

    private

      def set_context_node
        @context_node = Node.find(params[:brand_id])
      end

      def calendar_scope
        ProfessionalCalendar.where(
          "professional_node_id = :node_id OR context_node_id = :node_id",
          node_id: @context_node.id
        )
      end

      def set_calendar
        @calendar = calendar_scope.find(params[:id])
      end

      def calendar_params
        params.require(:professional_calendar).permit(:context_node_id, :title, :slug, :short_label, :description, :color, :active)
      end
  end
end
