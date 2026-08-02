module Brands
  module Impegno
    class PlacesController < ApplicationController
      layout "landing"

      before_action :set_place, only: %i[edit update destroy]

      def index
        @places = current_profile.impegno_places.order(:name)
        @place = current_profile.impegno_places.build
        render layout: false if params[:workspace] == "1"
      end

      def create
        @place = current_profile.impegno_places.build(place_params)
        if @place.save
          redirect_to impegno_path(area: "places"), notice: "Luogo aggiunto."
        else
          @places = current_profile.impegno_places.order(:name)
          render :index, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        if @place.update(place_params)
          redirect_to impegno_path(area: "places"), notice: "Luogo aggiornato."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @place.destroy!
        redirect_to impegno_path(area: "places"), notice: "Luogo eliminato."
      end

      private

        def set_place
          @place = current_profile.impegno_places.find(params[:id])
        end

        def place_params
          params.require(:impegno_place).permit(:name, :kind, :address, :online_url, :notes)
        end
    end
  end
end
