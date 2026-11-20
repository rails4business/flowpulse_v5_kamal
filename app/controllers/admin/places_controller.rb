module Admin
  # Registro dei luoghi in Flowpulse: si creano, si modificano, si chiudono e si collegano ai domini.
  class PlacesController < BaseController
    before_action :require_superadmin!
    before_action :set_place, only: %i[edit update]

    def index
      @domains = available_domains
      @domain = @domains.find { |domain| domain.hostname == params[:dominio] }
      places = Place.includes(place_domains: %i[domain content]).order(:status, :name)
      places = places.where(id: @domain.place_domains.select(:place_id)) if @domain
      @places = places
    end

    def new
      @place = Place.new
    end

    def create
      @place = Place.new(place_params.merge(created_by_profile: Current.user&.profile))
      if @place.save
        redirect_to edit_flowpulse_place_path(@place), notice: "Luogo creato. Ora collegalo ai domini."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @domains = available_domains
    end

    def update
      if @place.update(place_params)
        redirect_to edit_flowpulse_place_path(@place), notice: "Luogo aggiornato."
      else
        @domains = available_domains
        render :edit, status: :unprocessable_entity
      end
    end

    private

      def set_place
        @place = Place.find(params[:id])
      end

      def place_params
        params.require(:place).permit(
          :name, :slug, :address, :city, :province, :latitude, :longitude,
          :status, :closed_on, :description, :directions_url,
          :publication_status, :publication_visibility, :published_at
        )
      end

      def available_domains
        Domain.active.where(canonical_host: [ nil, "" ]).where.not(node_id: nil).order(:hostname).to_a
      end
  end
end
