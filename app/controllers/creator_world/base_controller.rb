module CreatorWorld
  class BaseController < ApplicationController
    before_action :require_creator_world_access!

    private

    def require_creator_world_access!
      return if superadmin?

      require_role!(:ideatore)
    end
  end
end
