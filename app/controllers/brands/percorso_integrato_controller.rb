module Brands
  class PercorsoIntegratoController < ApplicationController
    layout "landing"
    allow_unauthenticated_access

    def index
      load_site
    end

    private

    def load_site
      data = PercorsoIntegratoCatalog.load
      @site = data.fetch("site")
      @principles = data.fetch("principles", [])
      @roles = data.fetch("roles", [])
      @steps = data.fetch("steps", [])
    end
  end
end
