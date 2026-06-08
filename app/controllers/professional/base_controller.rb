module Professional
  class BaseController < ApplicationController
    before_action -> { require_role!(:professional) }
  end
end
