module Admin
  class DomainsController < BaseController
    dashboard_section :domains

    before_action :require_superadmin!
    before_action :set_domain, only: %i[show edit update destroy]

    def index
      @domains = Domain.includes(:node, :role_assignment).order(:hostname)
      @domain_audit = DomainArchitectureAudit.new(@domains).call
      performance_document = Performance::DomainBudgetCatalog.new.validate.document
      @publication_audits = @domains.index_with do |domain|
        DomainPublicationAudit.new(domain, domains: @domains, performance_document:).call
      end
    end

    def show
      domains = Domain.includes(:node, :role_assignment).order(:hostname)
      performance_document = Performance::DomainBudgetCatalog.new.validate.document
      @publication_audit = DomainPublicationAudit.new(@domain, domains:, performance_document:).call
    end

    def new
      @domain = Domain.new(locale: "it", target_controller: "landing", active: true, security_profile: "standard")
    end

    def edit
    end

    def create
      @domain = Domain.new(domain_params)

      if @domain.save
        redirect_to admin_domain_path(@domain), notice: "Dominio creato."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @domain.update(domain_params)
        redirect_to admin_domain_path(@domain), notice: "Dominio aggiornato."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @domain.destroy
      redirect_to admin_domains_path, notice: "Dominio eliminato."
    end

    def export
      if yaml_export_request?
        timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
        send_data Domain.export_to_yaml,
          filename: "flowpulse_domains_#{timestamp}.yml",
          type: "application/x-yaml; charset=utf-8",
          disposition: "attachment"
      else
        render :export
      end
    end

    def import
      uploaded_file = params[:domains_file]

      if uploaded_file.blank?
        redirect_to export_admin_domains_path, alert: "Seleziona un file YAML da importare."
        return
      end

      Domain.import_from_yaml!(uploaded_file.read)
      redirect_to admin_domains_path, notice: "Domini importati."
    rescue Psych::SyntaxError, NoMethodError, ArgumentError => error
      redirect_to export_admin_domains_path, alert: "YAML non valido: #{error.message}"
    end

    private
      def set_domain
        @domain = Domain.find(params[:id])
      end

      def domain_params
        params.require(:domain).permit(:hostname, :canonical_host, :locale, :target_controller, :target_action, :site_key, :primary, :active, :role_assignment_id, :node_id, :logo_full_url, :logo_square_url, :site_title, :site_description, :favicon_url, :social_image_url, :llms_enabled, :llms_summary, :llms_instructions, :security_profile)
      end

      def yaml_export_request?
        params[:format].to_s.in?(%w[yml yaml]) || request.format.to_s.include?("yaml")
      end
  end
end
