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

      helper_method :format_label, :content_domain

      # Una sola tabella: i Content del brand e quelli del titolare, con il dominio da cui escono e il tipo.
      def index
        contents = manageable_contents.includes(:node, :parent).order(:format, :position, :title).to_a
        @domain_choices = contents.map { |content| content_domain(content) }.compact.uniq.sort
        @format_choices = contents.map(&:format).uniq.sort_by { |format| format_label(format) }
        @domain = params[:dominio].presence_in(@domain_choices)
        @format = params[:tipo].presence_in(@format_choices)
        @contents = contents.select { |content| (@domain.nil? || content_domain(content) == @domain) && (@format.nil? || content.format == @format) }
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

        # Il dominio del primo node con un Domain attivo risalendo dal node del Content.
        def content_domain(content)
          @content_domains ||= {}
          @content_domains.fetch(content.node_id) do
            site = content.node.site_node
            @content_domains[content.node_id] = site && (site.primary_domain || site.domains.active.order(:hostname).first)&.hostname
          end
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
