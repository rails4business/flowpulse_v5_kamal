class ProfilesController < ApplicationController
  def show
    @user = Current.user
    @profile = @user.profile
    @email_change_authorized = @user.email_change_authorized_at&.after?(30.minutes.ago)
    load_pending_data_commitment_imports
  end

  def update
    @user = Current.user
    @profile = @user.profile
    @email_change_authorized = @user.email_change_authorized_at&.after?(30.minutes.ago)
    load_pending_data_commitment_imports
    attributes = email_update_params

    unless @user.email_change_authorized_at&.after?(30.minutes.ago)
      flash.now[:alert] = "Per modificare l’email, reimposta prima la password tramite il link temporaneo ricevuto dall’amministratore."
      return render :show, status: :unprocessable_entity
    end

    @user.email_address = attributes[:email_address]
    if @user.save
      @user.update_column(:email_change_authorized_at, nil)
      redirect_to profile_path, notice: "Email aggiornata."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  def details
    @user = Current.user
    @profile = @user.profile || @user.create_profile!(display_name: @user.email_address.to_s.split("@").first)
    @email_change_authorized = @user.email_change_authorized_at&.after?(30.minutes.ago)
    load_pending_data_commitment_imports

    if @profile.update(profile_details_params)
      redirect_to profile_path, notice: "Dettagli del profilo aggiornati."
    else
      flash.now[:alert] = @profile.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private

    def email_update_params
      params.require(:user).permit(:email_address)
    end

    def profile_details_params
      params.require(:profile).permit(:display_name, :first_name, :last_name, :username)
    end

    def load_pending_data_commitment_imports
      @pending_data_commitment_imports = @profile ? @profile.data_commitment_imports.awaiting_profile_confirmation.order(created_at: :desc) : DataCommitmentImport.none
    end
end
