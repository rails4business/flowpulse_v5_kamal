module CreatorWorld
  class BaseController < ApplicationController
    before_action -> { require_role!(:ideatore) }
  end
end
