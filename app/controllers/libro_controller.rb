class LibroController < ApplicationController
  layout false

  allow_unauthenticated_access only: %i[index show legacy_index legacy_show] if respond_to?(:allow_unauthenticated_access)

  DEFAULT_BOOK_SLUG = "il-corpo-un-mondo-da-scoprire"
  BOOKS_ROOT = Rails.root.join("config", "data", "books")

  before_action :set_book_paths
  before_action :ensure_book_exists, only: %i[index show guida]
  before_action :load_toc
  helper_method :book_reader_chapter_path, :book_reader_guida_path

  def index
    redirect_to book_chapter_path(book_slug: @book_slug, id: "copertina")
  end

  def legacy_index
    redirect_to book_chapter_path(book_slug: DEFAULT_BOOK_SLUG, id: "copertina"), status: :moved_permanently
  end

  def legacy_show
    legacy_chapter_slug = params[:id].to_s.presence || "copertina"
    redirect_to book_chapter_path(book_slug: DEFAULT_BOOK_SLUG, id: legacy_chapter_slug), status: :moved_permanently
  end

  def legacy_guida
    redirect_to book_guida_path(book_slug: DEFAULT_BOOK_SLUG), status: :moved_permanently
  end

  def show
    slug = params[:id].to_s
    @chapter_slug = slug.gsub(/[^a-zA-Z0-9\-_\.]/, "").sub(/\.md\z/, "")

    if @chapter_slug == "copertina"
      @is_cover = true
      @chapter_title = @book_metadata["title"].presence || @book_slug.titleize
      @chapter_description = @book_metadata["subtitle"].presence
      @chapter_markdown = ""

      chapters_only = @toc.reject { |item| item[:header] || item[:type] == "head" }
      @prev_chapter = nil
      @next_chapter = chapters_only.find { |c| c[:slug] != "copertina" }
    else
      @is_cover = false
      file_path = find_book_file(@book_md_dir, @chapter_slug)

      if file_path && File.exist?(file_path)
        raw = File.read(file_path)
        frontmatter, body = extract_frontmatter(raw)
        file_meta = book_file_metadata(file_path)
        chapter_meta = @toc.find { |c| c[:slug] == @chapter_slug || c[:slug] == file_meta[:slug] }

        @chapter_slug = file_meta[:slug].presence || @chapter_slug
        @chapter_title = frontmatter["title"].presence || chapter_meta&.dig(:title) || @chapter_slug.titleize
        @chapter_description = frontmatter["description"].presence || chapter_meta&.dig(:description)
        
        # Access level check
        access = (frontmatter["access"] || "draft").to_s.strip.downcase
        is_superadmin = Current.user&.superadmin_user?

        if hidden_access?(access) && !is_superadmin
          render plain: "Contenuto non trovato per #{@chapter_slug}", status: :not_found
          return
        elsif access == "draft" && !is_superadmin
          @is_draft = true
          @chapter_markdown = "*Questo capitolo è attualmente in fase di scrittura/bozza e sarà disponibile a breve. Torna presto a trovarci per leggerne i contenuti!*"
        else
          @is_draft = false
          @chapter_markdown = body
        end

        # Determine pagination from TOC
        chapters_only = @toc.reject { |item| item[:header] || item[:type] == "head" }
        
        # Let's normalize slugs for matching
        normalize = ->(s) { s.to_s.sub(/\.md\z/, "") }
        current_index = chapters_only.index { |c| normalize.call(c[:slug]) == normalize.call(@chapter_slug) }

        if current_index.nil? && frontmatter["slug"].present?
          target_slug = normalize.call(frontmatter["slug"])
          current_index = chapters_only.index { |c| normalize.call(c[:slug]) == target_slug }
        end

        if current_index
          @prev_chapter = current_index > 0 ? chapters_only[current_index - 1] : nil
          @next_chapter = current_index < chapters_only.length - 1 ? chapters_only[current_index + 1] : nil
        end
      else
        render plain: "Contenuto non trovato per #{@chapter_slug}", status: :not_found
        return
      end
    end
  end

  def guida
    @is_superadmin = Current.user&.superadmin_user?
    unless @is_superadmin
      redirect_to root_path, alert: "Non sei autorizzato ad accedere a questa pagina."
      return
    end
  end

  private

  def set_book_paths
    @book_slug = params[:book_slug].presence || DEFAULT_BOOK_SLUG
    @book_slug = @book_slug.to_s.gsub(/[^a-zA-Z0-9\-_]/, "")
    @book_dir = BOOKS_ROOT.join(@book_slug)
    @book_md_dir = @book_dir.join("chapters")
    @book_yaml_path = @book_dir.join("index.yml")
    @book_metadata_path = @book_dir.join("book.yml")
    @book_metadata = load_book_metadata
  end

  def ensure_book_exists
    return if Dir.exist?(@book_dir)

    fallback_location = if @book_slug == DEFAULT_BOOK_SLUG
      root_path
    else
      book_path(book_slug: DEFAULT_BOOK_SLUG)
    end

    redirect_back fallback_location: fallback_location, alert: "Libro non trovato."
  end

  def load_book_metadata
    return {} unless File.exist?(@book_metadata_path)

    YAML.safe_load_file(@book_metadata_path, permitted_classes: [], aliases: false) || {}
  rescue StandardError
    {}
  end

  def load_toc
    return @toc = [] unless File.exist?(@book_yaml_path)

    yaml_data = YAML.load_file(@book_yaml_path)
    counter = 0
    section_counter = 0
    chapter_counter = 0
    standalone_counter = 0
    access_map = build_access_map

    @toc = yaml_data.each_with_object([]) do |item, entries|
      type = item["type"].presence || "chapter"
      is_header = item["header"] == true || type == "head"
      slug = item["slug"]
      access = access_map[slug].presence || item["access"].presence || "draft"

      next if hidden_access?(access)

      chapter_num = nil
      outline_number = nil

      unless is_header
        counter += 1
        chapter_num = counter
      end

      case type
      when "section"
        section_counter += 1
        chapter_counter = 0
        outline_number = section_counter.to_s
      when "chapter"
        if section_counter.positive?
          chapter_counter += 1
          outline_number = "#{section_counter}.#{chapter_counter}"
        else
          standalone_counter += 1
          outline_number = standalone_counter.to_s
        end
      end

      entries << {
        title: item["title"],
        slug: slug,
        type: type,
        header: is_header,
        description: item["description"],
        color: item["color"],
        chapter_number: chapter_num,
        outline_number: outline_number,
        access: access
      }
    end
  end

  def build_access_map
    map = {}
    return map unless Dir.exist?(@book_md_dir)

    Dir.glob(@book_md_dir.join("*.md")).each do |path|
      text = File.read(path)
      fm = text.match(/\A---\n(.*?)\n---\n/m)
      next unless fm
      front = YAML.safe_load(fm[1], permitted_classes: [], aliases: false) || {}
      slug = front["slug"].presence || book_file_metadata(path)[:slug]
      slug = slug.to_s.sub(/\.md\z/, "")
      access = front["access"].to_s.strip.downcase
      map[slug] = access if slug.present?
    rescue StandardError
      next
    end
    map
  end

  def hidden_access?(access)
    access.to_s.strip.downcase.in?(%w[hide hidden])
  end

  def find_book_file(dir, safe_slug_base)
    file_path = dir.join("#{safe_slug_base}.md")
    return file_path if File.exist?(file_path)

    match = Dir.glob(dir.join("*.md")).find do |path|
      book_file_metadata(path)[:slug] == safe_slug_base
    end
    return Pathname.new(match) if match

    match = Dir.glob(dir.join("*#{safe_slug_base}.md")).first
    return Pathname.new(match) if match

    Dir.glob(dir.join("*.md")).each do |path|
      text = File.read(path)
      fm = text.match(/\A---\n(.*?)\n---\n/m)
      next unless fm
      front = YAML.safe_load(fm[1], permitted_classes: [], aliases: false) || {}
      file_slug = front["slug"].to_s.sub(/\.md\z/, "")
      return Pathname.new(path) if file_slug == safe_slug_base
    rescue StandardError
      next
    end

    nil
  end

  def book_file_metadata(path)
    basename = File.basename(path.to_s, ".md")
    match = basename.match(/\A(?<number>\d+)[-_](?<type>chapter|section|head)[-_](?<slug>.+)\z/i)
    return { number: nil, type: "chapter", slug: basename } unless match

    {
      number: match[:number].rjust(3, "0"),
      type: match[:type].downcase,
      slug: match[:slug].sub(/\.md\z/, "")
    }
  end

  def extract_frontmatter(text)
    match = text.match(/\A---\n(.*?)\n---\n/m)
    return [{}, text] unless match

    frontmatter = YAML.safe_load(match[1], permitted_classes: [], aliases: false) || {}
    body = text.sub(/\A---\n(.*?)\n---\n/m, "")
    [frontmatter, body]
  rescue StandardError
    [{}, text]
  end

  def book_reader_chapter_path(chapter_slug)
    book_chapter_path(book_slug: @book_slug, id: chapter_slug)
  end

  def book_reader_guida_path
    book_guida_path(book_slug: @book_slug)
  end
end
