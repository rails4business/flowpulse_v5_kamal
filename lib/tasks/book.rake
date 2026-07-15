# frozen_string_literal: true

# se vuoi ordinare index  è in bin
# bin/rails book:generate_md
namespace :book do
  DEFAULT_BOOK_SLUG = "il-corpo-un-mondo-da-scoprire"

  desc "Genera file markdown numerati nella cartella book"
  task generate_md: :environment do
    require "yaml"
    require "fileutils"

    source = Rails.root.join("config/data/book_index.yml")
    target_dir = Rails.root.join("config/data/book")

    FileUtils.mkdir_p(target_dir)

    data = YAML.load_file(source)

    index = 1

    data.each do |item|
      number = index.to_s.rjust(2, "0")
      slug   = item["slug"]
      file   = "#{number}-#{slug}.md"
      path   = target_dir.join(file)

      if File.exist?(path)
        puts "⏭️  Skipping existing file: #{file}"
        index += 1
        next
      end

      content = <<~MD
        ---
        title: "#{item["title"]}"
        description: "#{item["description"]}"
        slug: "#{slug}"
        color: "#{item["color"]}"
        ---

        # #{item["title"]}

      MD

      File.write(path, content)
      puts "✅ Created #{file}"

      index += 1
    end

    puts "📚 Generazione completata (#{index - 1} file)"
  end

  desc "Rigenera da zero i file markdown del libro partendo dallo YAML. Dry-run di default, usa APPLY=1 per scrivere."
  task regenerate_from_yml: :environment do
    require "json"
    require "yaml"
    require "fileutils"

    apply = ENV["APPLY"].to_s == "1"
    force = ENV["FORCE"].to_s == "1"
    book_slug = selected_book_slug
    book_dir = book_directory(book_slug)
    chapters_dir = book_chapters_directory(book_slug)
    book_index = book_index_path(book_slug)

    raise "File YAML non trovato: #{book_index}" unless File.exist?(book_index)

    entries = YAML.safe_load_file(book_index, permitted_classes: [], aliases: false) || []
    raise "Formato YAML inatteso: #{book_index} deve contenere un array" unless entries.is_a?(Array)

    existing_markdown_files = Dir.glob(chapters_dir.join("*.md"))
    generated_files = entries.map { |entry| chapters_dir.join(book_filename(entry)) }

    puts "== Regenerate book markdown from YAML =="
    puts "Book:  #{book_slug}"
    puts "Index: #{book_index}"
    puts "Dir:   #{book_dir}"
    puts "Text:  #{chapters_dir}"
    puts "Mode:  #{apply ? "APPLY (scrive file)" : "DRY RUN (anteprima)"}"
    puts
    puts "File .md esistenti: #{existing_markdown_files.size}"
    puts "File .md da generare: #{generated_files.size}"
    puts

    entries.each do |entry|
      puts "#{apply ? "write" : "would write"} #{book_filename(entry)}"
    end

    unless apply
      puts
      puts "Nessun file modificato. Per rigenerare davvero usa:"
      puts "  APPLY=1 BOOK=#{book_slug} bin/rails book:regenerate_from_yml"
      next
    end

    if existing_markdown_files.any? && !force
      backup_dir = Rails.root.join("tmp", "book_backups", "#{book_slug}-#{Time.current.strftime("%Y%m%d-%H%M%S")}")
      FileUtils.mkdir_p(backup_dir)
      existing_markdown_files.each { |path| FileUtils.cp(path, backup_dir.join(File.basename(path))) }
      puts
      puts "Backup creato: #{backup_dir}"
    end

    FileUtils.rm_f(existing_markdown_files)
    FileUtils.mkdir_p(chapters_dir)

    entries.each do |entry|
      path = chapters_dir.join(book_filename(entry))
      File.write(path, book_markdown_template(entry))
    end

    puts
    puts "Rigenerazione completata: #{generated_files.size} file .md"
  end

  def selected_book_slug
    ENV["BOOK"].presence || DEFAULT_BOOK_SLUG
  end

  def book_directory(book_slug)
    Rails.root.join("config", "data", "books", book_slug)
  end

  def book_index_path(book_slug)
    book_directory(book_slug).join("index.yml")
  end

  def book_chapters_directory(book_slug)
    book_directory(book_slug).join("chapters")
  end

  def book_filename(entry)
    number = entry.fetch("number").to_s.rjust(3, "0")
    type = entry.fetch("type", "chapter").to_s.presence || "chapter"
    slug = entry.fetch("slug").to_s.sub(/\.md\z/, "")

    "#{number}-#{type}-#{slug}.md"
  end

  def book_markdown_template(entry)
    title = entry["title"].to_s
    frontmatter = {
      "title" => title,
      "description" => entry["description"].to_s,
      "color" => entry["color"].presence || "neutro",
      "access" => entry["access"].presence || "draft"
    }

    <<~MD
      ---
      #{frontmatter.map { |key, value| "#{key}: #{JSON.generate(value)}" }.join("\n")}
      ---

      # #{title}

    MD
  end
end
