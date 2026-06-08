module Tutor
  class BaseController < ApplicationController
    before_action -> { require_role!(:tutor) }
  end
end
