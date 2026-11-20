module Brands
  module Admin
    # Pubblicazione dei Content del brand, modificata direttamente: i Content del node del brand e dei suoi
    # discendenti e, nel brand del titolare, i suoi Content che stanno in altri brand. Il testo resta nei file.
    class ContentsController < BaseController
      FORMAT_LABELS = {
        "course" => "Corso", "chapter" => "Capitolo", "post" => "Articolo", "insegnante" => "Insegnante",
        "professionista" => "Professionista", "founder" => "Founder", "centro" => "Centro", "scuola" => "Scuola",
        "metodica" => "Metodica"
      }.freeze

      helper_method :format_label

      def index
        @format = params[:tipo].presence_in(Content::FORMATS)
        @brand_contents = filtered(Content.in_tree_of(@brand))
        @owner_profile = @brand.primary_professional_profile
        @owned_elsewhere = @owner_profile ? filtered(Content.where(profile: @owner_profile).where.not(id: Content.in_tree_of(@brand).select(:id))) : Content.none
      end

      def update
        content = manageable_contents.find(params[:id])
        if content.update(content_params)
          redirect_back_or_to brand_admin_contents_path(@brand.slug), notice: "#{content.title}: pubblicazione aggiornata."
        else
          redirect_back_or_to brand_admin_contents_path(@brand.slug), alert: content.errors.full_messages.to_sentence
        end
      end

      private

        def format_label(format)
          FORMAT_LABELS.fetch(format, format.humanize)
        end

        def filtered(scope)
          scope = scope.where(format: @format) if @format
          scope.includes(:node, :parent).order(:format, :position, :title)
        end

        def manageable_contents
          owner = @brand.primary_professional_profile
          scope = Content.in_tree_of(@brand)
          owner ? scope.or(Content.where(profile: owner)) : scope
        end

        def content_params
          attributes = params.require(:content).permit(:publication_status, :publication_visibility, :published_at, :revised_at, access_modes: [])
          attributes[:access_modes] = Array(attributes[:access_modes]).compact_blank if attributes.key?(:access_modes)
          attributes
        end
    end
  end
end
