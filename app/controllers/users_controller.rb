class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
    @user.build_profile
  end

  def create
    @user = User.new(user_params)
    @user.build_profile

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Registrazione completata."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
