module Brands
  module Impegno
    class ComposerController < ApplicationController
      include ImpegnoSkillAccess
      before_action :require_current_domain_impegno_skill!
      layout "landing"

      before_action -> { require_permission!(:superadmin) }

      def show; end
    end
  end
end
