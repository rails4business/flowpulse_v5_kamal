module Flowpulse
  class DevelopmentController < Admin::BaseController
    layout "landing"

    before_action :require_superadmin!

    def index
      repository = FlowpulseDevelopmentRepository.new
      @development_statuses = FlowpulseDevelopmentRepository::STATUSES
      @development_brands = repository.brand_directory.values.sort_by { |brand| brand.fetch("label").downcase }
      @selected_brand = params[:brand].presence
      @selected_status = params[:status].presence

      entries = repository.entries
      entries = entries.select { |entry| entry.fetch("owner_brand") == @selected_brand } if @selected_brand.present?
      entries = entries.select { |entry| entry.fetch("status") == @selected_status } if @selected_status.present?
      @development_groups = entries.group_by { |entry| entry.fetch("owner_brand") }.map do |brand_key, brand_entries|
        [repository.brand_directory.fetch(brand_key), brand_entries]
      end.sort_by { |brand, _entries| brand.fetch("label").downcase }
    rescue ArgumentError, KeyError => error
      raise ActiveRecord::RecordNotFound, error.message
    end

    def show
      @development_entry = FlowpulseDevelopmentRepository.new.find(params[:slug])
      raise ActiveRecord::RecordNotFound, "Scheda di implementazione non trovata" unless @development_entry
    rescue ArgumentError, KeyError => error
      raise ActiveRecord::RecordNotFound, error.message
    end
  end
end
