module Brands
  module Impegno
    class HomeController < ApplicationController
      layout "landing"
      allow_unauthenticated_access

      def index; end
    end
  end
end
