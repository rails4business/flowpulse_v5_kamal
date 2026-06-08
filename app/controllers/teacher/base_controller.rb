module Teacher
  class BaseController < ApplicationController
    before_action -> { require_role!(:teacher) }
  end
end
