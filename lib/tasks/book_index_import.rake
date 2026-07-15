# frozen_string_literal: true

require "yaml"

namespace :book do
  desc "Importa l'indice del libro nel tree Taxbranch.
        Usage:
          PARENT_SLUG=book/slug bin/rails book:import_index
          oppure
          PARENT_ID=42 bin/rails book:import_index"
  task import_index: :environment do
    parent =
      if ENV["PARENT_ID"].present?
        Taxbranch.find_by(id: ENV["PARENT_ID"])
      elsif ENV["PARENT_SLUG"].present?
        Taxbranch.find_by(slug: ENV["PARENT_SLUG"])
      end

    raise "Imposta PARENT_ID o PARENT_SLUG per individuare il taxbranch genitore" unless parent

    data = YAML.load_file(Rails.root.join("config/data/book_index.yml"))

    data.each_with_index do |item, idx|
      slug_base   = item["slug"].presence || item["title"].parameterize
      category    = item["header"] ? "header_chapter_book" : "chapter"
      branch_slug = "#{category}/#{slug_base}"

      branch = Taxbranch.find_or_initialize_by(slug: branch_slug)
      branch.assign_attributes(
        parent:       parent,
        lead:         parent.lead,
        slug_category: category,
        slug_label:   item["title"],
        position:     idx + 1,
        notes:        item["description"]
      )
      branch.save!

      post = branch.post || branch.build_post
      post.assign_attributes(
        lead:        parent.lead,
        title:       item["title"],
        slug:        slug_base,
        description: item["description"]
      )
      post.save!
    end

    puts "Import completato: #{data.size} nodi sincronizzati sotto #{parent.slug}"
  end
end
