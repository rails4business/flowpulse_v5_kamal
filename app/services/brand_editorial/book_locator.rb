module BrandEditorial
  # Trova un libro per slug senza legarlo al dominio che lo mostra.
  # La posizione canonica è config/data/brands/<brand>/books/<slug>;
  # config/data/books resta una compatibilità di migrazione.
  class BookLocator
    BRANDS_ROOT = Rails.root.join("config/data/brands").freeze
    LEGACY_ROOT = Rails.root.join("config/data/books").freeze
    SLUG_PATTERN = /\A[a-z0-9]+(?:[a-z0-9-]*[a-z0-9])?\z/

    def find(slug)
      normalized = normalize_slug(slug)
      canonical = brand_book_directories(normalized).find(&:directory?)
      return canonical if canonical

      legacy = LEGACY_ROOT.join(normalized)
      legacy if legacy.directory?
    end

    def all
      canonical = Dir.glob(BRANDS_ROOT.join("*", "books", "*", "book.yml")).map { |path| Pathname(path) }
      legacy = Dir.glob(LEGACY_ROOT.join("*", "book.yml")).map { |path| Pathname(path) }

      (canonical + legacy).each_with_object({}) do |metadata_path, books|
        slug = metadata_path.dirname.basename.to_s
        books[slug] ||= metadata_path.dirname
      end
    end

    private

    def normalize_slug(slug)
      normalized = slug.to_s
      raise Editorial::InvalidKeyError, "Slug libro non valido: #{normalized.inspect}" unless normalized.match?(SLUG_PATTERN)

      normalized
    end

    def brand_book_directories(slug)
      Dir.glob(BRANDS_ROOT.join("*", "books", slug)).map { |path| Pathname(path) }.sort_by(&:to_s)
    end
  end
end
