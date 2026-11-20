module Admin
  # Un luogo in un dominio, con il Content facoltativo che lo racconta lì.
  class PlaceDomainsController < BaseController
    before_action :require_superadmin!
    before_action :set_place

    def create
      place_domain = @place.place_domains.new(place_domain_params)
      if place_domain.save
        redirect_to edit_flowpulse_place_path(@place), notice: "Dominio collegato."
      else
        redirect_to edit_flowpulse_place_path(@place), alert: place_domain.errors.full_messages.to_sentence
      end
    end

    def update
      place_domain = @place.place_domains.find(params[:id])
      if place_domain.update(place_domain_params.except(:domain_id))
        redirect_to edit_flowpulse_place_path(@place), notice: "Collegamento aggiornato."
      else
        redirect_to edit_flowpulse_place_path(@place), alert: place_domain.errors.full_messages.to_sentence
      end
    end

    def destroy
      @place.place_domains.find(params[:id]).destroy!
      redirect_to edit_flowpulse_place_path(@place), notice: "Dominio scollegato."
    end

    private

      def set_place
        @place = Place.find(params[:place_id])
      end

      def place_domain_params
        params.require(:place_domain).permit(:domain_id, :content_id, :position)
      end
  end
end
