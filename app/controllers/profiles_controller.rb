class ProfilesController < ApplicationController
  def show
    @user = Current.user
    @profile = @user.profile
  end
end
