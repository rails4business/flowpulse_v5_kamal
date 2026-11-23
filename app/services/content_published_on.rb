# Date di prima pubblicazione dei Content già scritti prima della pubblicazione diretta. Le date si calcolano
# in locale (written_on del file, altrimenti il primo commit del file; per un corso il capitolo più vecchio) e si
# salvano in un file, perché in produzione il git non c'è. Poi si applicano: le bozze diventano pubblicate.
class ContentPublishedOn
  DEFAULT_PATH = Rails.root.join("config/data/contents_published_on.yml")

  Result = Data.define(:published, :missing)

  def initialize(path: DEFAULT_PATH)
    @path = Pathname(path)
  end

  def generate!
    dates = Content.order(:key).to_h { |content| [ content.key, own_date(content) ] }
    Content.where(format: "course").find_each do |course|
      dates[course.key] ||= course.children.filter_map { |chapter| dates[chapter.key] }.min
    end
    dates = dates.compact.sort_by { |key, date| [ date, key ] }.to_h
    @path.write(dates.transform_values(&:iso8601).to_yaml)
    dates
  end

  def publish!(dry_run: false)
    dates = YAML.safe_load(@path.read).to_h
    published = 0
    missing = []
    Content.where(publication_status: "draft").find_each do |content|
      date = dates[content.key]
      next missing << content.key if date.blank?

      published += 1
      next if dry_run

      content.update!(publication_status: "published", publication_visibility: "public", published_at: Date.iso8601(date.to_s).in_time_zone.change(hour: 9))
    end
    Result.new(published:, missing:)
  end

  private

    def own_date(content)
      return content.written_on if content.written_on
      return if content.source_path.blank?

      first = `git log --follow --diff-filter=A --format=%as -- #{Shellwords.escape(content.source_path)} 2>/dev/null`.split.last
      first && Date.iso8601(first)
    end
end
