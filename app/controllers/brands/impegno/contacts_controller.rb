module Brands
  module Impegno
    class ContactsController < ApplicationController
      layout "landing"

      before_action :set_contact, only: %i[edit update destroy]

      def index
        @contacts = current_profile.impegno_contacts.order(:name)
        @contact = current_profile.impegno_contacts.build
        render layout: false if params[:workspace] == "1"
      end

      def create
        @contact = current_profile.impegno_contacts.build(contact_params)
        if @contact.save
          redirect_to impegno_path(area: "contacts"), notice: "Contatto aggiunto."
        else
          @contacts = current_profile.impegno_contacts.order(:name)
          render :index, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        if @contact.update(contact_params)
          redirect_to impegno_path(area: "contacts"), notice: "Contatto aggiornato."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @contact.destroy!
        redirect_to impegno_path(area: "contacts"), notice: "Contatto eliminato."
      end

      private

        def set_contact
          @contact = current_profile.impegno_contacts.find(params[:id])
        end

        def contact_params
          params.require(:impegno_contact).permit(:name, :kind, :email, :phone, :notes)
        end
    end
  end
end
