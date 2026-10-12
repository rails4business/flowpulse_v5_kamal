module Brands
  module Rails4business
    class SkillProductsController < ApplicationController
      layout "landing"

      before_action :set_skill
      before_action :set_product, only: %i[show update]

      def show
        @activations = @skill.reusable_skill_nodes.includes(:node).order("nodes.title")
      end

      def create
        activation = @skill.reusable_skill_nodes.find(product_params.fetch(:reusable_skill_node_id))
        @product = activation.skill_products.new(product_attributes)
        @product.created_by_profile = current_profile

        if assign_data && @product.save
          redirect_to rails4b_skill_product_path(@skill, @product), notice: "Prodotto creato."
        else
          redirect_to rails4b_skill_path(@skill), alert: @product.errors.full_messages.to_sentence
        end
      end

      def update
        activation = @skill.reusable_skill_nodes.find(product_params.fetch(:reusable_skill_node_id))
        @product.reusable_skill_node = activation
        @product.assign_attributes(product_attributes)

        if assign_data && @product.save
          redirect_to rails4b_skill_product_path(@skill, @product), notice: "Prodotto aggiornato."
        else
          @activations = @skill.reusable_skill_nodes.includes(:node).order("nodes.title")
          render :show, status: :unprocessable_entity
        end
      end

      private

        def set_skill
          @skill = current_profile.reusable_skills.find(params[:skill_id])
        end

        def set_product
          @product = @skill.skill_products.find(params[:id])
        end

        def product_params
          params.require(:skill_product).permit(
            :reusable_skill_node_id, :title, :slug, :status, :visibility,
            :format, :body, :source_path, :data_json
          )
        end

        def product_attributes
          product_params.except(:data_json)
        end

        def assign_data
          raw_data = product_params[:data_json].to_s.strip
          @product.data = raw_data.present? ? JSON.parse(raw_data) : {}
          unless @product.data.is_a?(Hash)
            @product.errors.add(:data, "deve contenere un oggetto JSON")
            return false
          end
          true
        rescue JSON::ParserError => error
          @product.errors.add(:data, "non è un JSON valido: #{error.message}")
          false
        end
    end
  end
end
