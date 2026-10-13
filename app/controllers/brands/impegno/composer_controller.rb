module Brands
  module Impegno
    class ComposerController < ApplicationController
      layout "landing"

      before_action -> { require_permission!(:superadmin) }

      def show; end
    end
  end
end
