require "json"

module Admin
  class DataCommitmentImportsController < BaseController
    dashboard_section :data_commitment_imports
    before_action :require_superadmin!

    def index
      @imports = DataCommitmentImport.order(created_at: :desc)
    end

    def export
      records = Brands::Impegno::Commitment.includes(:profile, :domain, :created_by_profile, :assignee_profile, :responsible_profile).order(:created_at)
      payload = DataCommitmentTransfer.payload_for(records)
      send_data JSON.pretty_generate(payload), filename: "data_commitments_#{Time.current.strftime('%Y%m%d_%H%M')}.json", type: "application/json", disposition: "attachment"
    end

    def queue_export
      records = Brands::Impegno::Commitment.includes(:profile, :domain, :created_by_profile, :assignee_profile, :responsible_profile).order(:created_at)
      grouped_records = records.group_by(&:profile)
      directory = Rails.root.join("storage", "data_commitment_exports", "pending")
      FileUtils.mkdir_p(directory)
      grouped_records.each do |profile, profile_records|
        payload = DataCommitmentTransfer.payload_for(profile_records)
        payload["target_profile_username"] = profile.username
        filename = "#{Time.current.strftime('%Y%m%d_%H%M%S')}_#{profile.username}.json"
        File.write(directory.join(filename), JSON.pretty_generate(payload))
      end
      redirect_to admin_data_commitment_imports_path, notice: "#{grouped_records.size} esportazioni messe in coda: al prossimo deploy verranno proposte ai rispettivi profili."
    end

    def create
      file = params[:file]
      parsed = JSON.parse(file.read)
      records = Array(parsed["commitments"])
      raise JSON::ParserError unless DataCommitmentTransfer.valid_payload?(parsed)
      DataCommitmentImport.create!(uploaded_by_user: Current.user, source_name: file.original_filename, payload: parsed, summary: DataCommitmentTransfer.summary(records))
      redirect_to admin_data_commitment_imports_path, notice: "File caricato: controlla l’anteprima e conferma l’importazione."
    rescue JSON::ParserError
      redirect_to admin_data_commitment_imports_path, alert: "Il file non è un’esportazione DataCommitment valida."
    end

    def apply
      import = DataCommitmentImport.find(params[:id])
      return redirect_to admin_data_commitment_imports_path, alert: "Questa importazione è già stata gestita." unless import.status == "pending"
      imported = DataCommitmentTransfer.apply!(import)
      import.update!(status: "applied", applied_at: Time.current, summary: import.summary.merge("applied" => imported))
      redirect_to admin_data_commitment_imports_path, notice: "Importati o aggiornati #{imported} impegni."
    rescue ActiveRecord::RecordInvalid, KeyError => error
      redirect_to admin_data_commitment_imports_path, alert: "Importazione non applicata: #{error.message}"
    end

    private
  end
end
