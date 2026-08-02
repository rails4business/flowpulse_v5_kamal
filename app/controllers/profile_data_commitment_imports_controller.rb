class ProfileDataCommitmentImportsController < ApplicationController
  def accept
    import = current_profile.data_commitment_imports.awaiting_profile_confirmation.find(params[:id])
    imported = DataCommitmentTransfer.apply!(import)
    import.update!(status: "applied", applied_at: Time.current, summary: import.summary.merge("applied" => imported))
    redirect_to profile_path, notice: "Importati #{imported} impegni nel tuo calendario."
  rescue ActiveRecord::RecordInvalid, KeyError => error
    redirect_to profile_path, alert: "Importazione non applicata: #{error.message}"
  end

  def reject
    import = current_profile.data_commitment_imports.awaiting_profile_confirmation.find(params[:id])
    import.update!(status: "rejected")
    redirect_to profile_path, notice: "Richiesta di importazione rifiutata."
  end
end
