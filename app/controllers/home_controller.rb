class HomeController < ApplicationController
  allow_unauthenticated_access
  before_action :require_authentication, only: [:dashboard]

  def index
  end

  def dashboard
  end

  def progetti
  end

  def lavoro
  end

  def salute
  end

  def elenco_pagine
    @registered_pages = ViewPagesController::PAGES
    # Prende tutti i file html dentro public/viste_html
    @html_files = Dir.glob(Rails.root.join('public', 'viste_html', '*.html')).map do |path|
      # Prende solo il nome del file
      File.basename(path)
    end.sort
  end
end
