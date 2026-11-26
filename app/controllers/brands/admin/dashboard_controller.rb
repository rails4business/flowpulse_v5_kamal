module Brands
  module Admin
    class DashboardController < BaseController
      def index
        @sections = dashboard_sections
      end

      private

        def brand_section_access?
          dashboard_access_context.capabilities.intersect?(%i[manage manage_access manage_requests manage_projects create_children])
        end

        def dashboard_sections
          return full_dashboard_sections if brand_owner? || Current.user&.superadmin_user?

          contextual_dashboard_sections
        end

        def full_dashboard_sections
          [
            section("Nodi", "Struttura, progetti e risorse del Brand.", brand_admin_nodes_path(@brand.slug), "NOD"),
            section("Schema", "Vista strutturale dei Node e dei collegamenti.", brand_admin_nodes_path(@brand.slug, view: "schema"), "SCH"),
            section("Sviluppo", "Decisioni, interventi e stato dello sviluppo.", brand_admin_development_path(@brand.slug), "DEV"),
            section("Richieste", "Richieste ricevute e flussi di accesso.", brand_admin_requests_path(@brand.slug), "REQ"),
            section("Contenuti", "Contenuti editoriali pubblicati dal Brand.", brand_admin_contents_path(@brand.slug), "CON"),
            section("Impegni", "Attività e impegni collegati al Brand.", brand_admin_data_commitments_path(@brand.slug), "IMP"),
            section("Privacy", "Configurazione privacy e protezione dei dati.", brand_admin_privacy_path(@brand.slug), "PRI")
          ]
        end

        def contextual_dashboard_sections
          capabilities = dashboard_access_context.capabilities
          sections = []
          if capabilities.include?(:manage_requests)
            sections << section("Richieste", "Richieste e accessi del perimetro consentito.", brand_admin_requests_path(@brand.slug), "REQ")
          end
          if @brand.slug == "generaimpresa" && capabilities.include?(:manage_access)
            sections << section("Persone", "Profile e BrandAccess GeneraImpresa.", genera_impresa_people_path, "PER")
          end
          if @brand.slug == "generaimpresa" && capabilities.intersect?(%i[manage_projects create_children])
            sections << section("Progetti", "Progetti affidati e persone collegate.", genera_impresa_my_projects_path, "PRJ")
          end
          sections
        end

        def section(title, description, path, code)
          { title:, description:, path:, code: }
        end
    end
  end
end
