module Admin
  class DomainsController < BaseController
    before_action :set_domain, only: %i[show edit update destroy]

    def index
      @domains = Domain.order(:hostname)
    end

    def show
    end

    def new
      @domain = Domain.new(locale: "it", action: "mvp_home", active: true)
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
        timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
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
        params.require(:domain).permit(:hostname, :canonical_host, :locale, :action, :target_controller, :target_action, :primary, :active)
      end

      def yaml_export_request?
        params[:format].to_s.in?(%w[yml yaml]) || request.format.to_s.include?("yaml")
      end
  end
end
