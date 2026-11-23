require "test_helper"

class ContentCatalogTest < ActiveSupport::TestCase
  setup do
    @root = Pathname(Dir.mktmpdir("content-catalog"))
    user = User.create!(email_address: "catalog-author@flowpulse.test", password: "password123", password_confirmation: "password123")
    @profile = user.create_profile!(display_name: "Autore", username: "catalog_author")
    role_assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
    @project = Node.create!(title: "Progetto", slug: "progetto-test", role_assignment: role_assignment)
    @author = Node.create!(title: "Autore", slug: "autore-test", node_type: "professional", role_assignment: role_assignment)
    @lesson = Node.create!(title: "Lezione", slug: "lezione-test", parent: @project, view_type: "course_lesson", role_assignment: role_assignment)
    @profile.update!(primary_node: @author)

    write "brands/progetto-test/courses/corso/course.yml", <<~YAML
      contents:
        - id: corso-test
          format: course
          slug: corso-test
          position: 1
          status: published
          visibility: public
          access: free
          title: Corso di prova
          description: Un corso.
          level: base
          author_node_slug: autore-test
          publisher_node_slug: progetto-test
        - id: corso-test-capitolo
          parent_id: corso-test
          format: chapter
          slug: capitolo
          position: 1
          status: published
          title: Capitolo
          content_path: brands/progetto-test/courses/corso/chapters/capitolo.md
        - id: corso-test-capitolo-lezione
          parent_id: corso-test
          lesson_node_slug: lezione-test
          format: chapter
          slug: capitolo-lezione
          position: 2
          title: Capitolo della lezione
    YAML
    write "brands/progetto-test/courses/corso/chapters/capitolo.md", "---\nauthor: Autore Test\nauthor_node_slug: autore-test\n---\n# Capitolo\n\nTesto.\n"
    write "brands/autore-test/contents/articolo/content.yml", <<~YAML
      slug: articolo-test
      title: Articolo
      excerpt: Breve presentazione.
      format: post
      author_node_slug: autore-test
      publication_at: "2026-08-27"
      category: consapevolezza
      status: published
      publications:
        - platform: youtube
          format: video
          url: https://youtube.com/watch?v=abc
          external_id: abc
    YAML
    write "brands/autore-test/contents/articolo/content.md", "Corpo dell'articolo.\n"
  end

  teardown do
    FileUtils.remove_entry(@root)
  end

  test "imports courses, chapters and articles with their node, body and author" do
    result = ContentCatalog.new(root: @root).import!

    assert_equal 4, result.contents
    assert_equal 4, result.created
    course = Content.find_by!(key: "corso-test")
    chapter = Content.find_by!(key: "corso-test-capitolo")
    article = Content.find_by!(key: "articolo-test")

    assert_equal @project, course.node
    assert_equal @project, chapter.node, "senza lezione il capitolo eredita il node del corso"
    lesson_chapter = Content.find_by!(key: "corso-test-capitolo-lezione")
    assert_equal @lesson, lesson_chapter.node, "il capitolo sta nel node della sua lezione"
    assert_equal course, lesson_chapter.parent
    assert_not lesson_chapter.data.key?("lesson_node_slug")
    assert_equal course, chapter.parent
    assert_equal "---\nauthor: Autore Test\nauthor_node_slug: autore-test\n---\n# Capitolo\n\nTesto.\n", chapter.body_md
    assert_equal [@profile], chapter.contributions.map(&:profile), "autore letto dall'intestazione del Markdown"
    assert chapter.source_checksum.present?
    assert_equal @author, article.node, "senza progetto l'articolo sta nel node dell'autore"
    assert_equal "Breve presentazione.", article.description
    assert_equal Date.new(2026, 8, 27), article.written_on
    assert_equal({ "level" => "base", "author_node_slug" => "autore-test", "publisher_node_slug" => "progetto-test" }, course.data)
    assert_equal [@profile], course.contributions.map(&:profile)
    assert_equal "autore", course.contributions.first.role
    assert_equal ["youtube"], article.publications.map(&:platform)
  end

  test "the owner is the author, chapters without author take the course owner, and import never changes it" do
    ContentCatalog.new(root: @root).import!

    course = Content.find_by!(key: "corso-test")
    assert_equal @profile, course.profile
    assert_equal @profile, Content.find_by!(key: "corso-test-capitolo-lezione").profile, "capitolo senza autore: titolare del corso"

    other = User.create!(email_address: "nuovo-titolare@flowpulse.test", password: "password123", password_confirmation: "password123").create_profile!(display_name: "Nuovo")
    course.update!(profile: other)
    ContentCatalog.new(root: @root).import!

    assert_equal other, course.reload.profile
  end

  test "an article can keep its text where it is with content_path" do
    write "autore-test/contenuti/articoli/2026-09-01-vecchio.md", "Testo rimasto al suo posto.\n"
    write "brands/autore-test/contents/vecchio/content.yml", <<~YAML
      slug: vecchio
      title: Articolo con il testo altrove
      format: post
      author_node_slug: autore-test
      content_path: autore-test/contenuti/articoli/2026-09-01-vecchio.md
    YAML

    ContentCatalog.new(root: @root).import!

    article = Content.find_by!(key: "vecchio")
    assert_equal "Testo rimasto al suo posto.\n", article.body_md
  end

  test "links to other contents are added from the YAML and never removed" do
    write "brands/progetto-test/contents/metodica-prova/content.yml", <<~YAML
      slug: metodica-prova
      title: Metodica di prova
      format: metodica
    YAML
    write "brands/progetto-test/contents/scuola-prova/content.yml", <<~YAML
      slug: scuola-prova
      title: Scuola di prova
      format: scuola
      links:
        metodica: [metodica-prova]
    YAML

    assert_equal 1, ContentCatalog.new(root: @root).import!.links
    assert_equal 0, ContentCatalog.new(root: @root).import!.links

    school = Content.find_by!(key: "scuola-prova")
    assert_equal [ [ "metodica", "metodica-prova" ] ], school.outgoing_links.map { |link| [ link.kind, link.target_content.key ] }
    assert_not school.data.key?("links")

    write "brands/progetto-test/contents/scuola-prova/content.yml", <<~YAML
      slug: scuola-prova
      title: Scuola di prova
      format: scuola
    YAML
    ContentCatalog.new(root: @root).import!
    assert_equal 1, school.outgoing_links.count
  end

  test "links can come from a node, such as the introductory course of a methodology" do
    write "brands/progetto-test/contents/metodica-dal-corso/content.yml", <<~YAML
      slug: metodica-dal-corso
      title: Metodica presentata da un corso
      format: metodica
      links_from_nodes:
        metodica: [lezione-test]
    YAML

    assert_equal 1, ContentCatalog.new(root: @root).import!.links
    assert_equal 0, ContentCatalog.new(root: @root).import!.links

    link = Content.find_by!(key: "metodica-dal-corso").incoming_links.sole
    assert_equal [ @lesson, "metodica" ], [ link.source_node, link.kind ]
    assert_equal [ link ], @lesson.outgoing_content_links.to_a
  end

  test "rejects links from unknown nodes" do
    write "brands/progetto-test/contents/metodica-orfana/content.yml", <<~YAML
      slug: metodica-orfana
      title: Metodica senza corso
      format: metodica
      links_from_nodes:
        metodica: [node-inesistente]
    YAML

    error = assert_raises(ArgumentError) { ContentCatalog.new(root: @root).import! }
    assert_match "legame da node sconosciuto node-inesistente", error.message
  end

  test "rejects links to unknown contents" do
    write "brands/progetto-test/contents/scuola-orfana/content.yml", <<~YAML
      slug: scuola-orfana
      title: Scuola senza metodica
      format: scuola
      links:
        metodica: [metodica-inesistente]
    YAML

    error = assert_raises(ArgumentError) { ContentCatalog.new(root: @root).import! }
    assert_match "legame verso chiave sconosciuta metodica-inesistente", error.message
  end

  test "status, visibility and access in the YAML never decide publication" do
    ContentCatalog.new(root: @root).import!

    Content.find_each do |content|
      assert_equal "draft", content.publication_status
      assert_equal "private", content.publication_visibility
      assert_equal [], content.access_modes
      assert_not content.data.key?("status")
    end
  end

  test "reimport updates structure and keeps the publication state of the environment" do
    ContentCatalog.new(root: @root).import!
    course = Content.find_by!(key: "corso-test")
    course.update!(publication_status: "published", publication_visibility: "public", access_modes: ["free"], published_at: 1.day.ago)

    write "brands/progetto-test/courses/corso/course.yml", File.read(@root.join("brands/progetto-test/courses/corso/course.yml")).sub("Corso di prova", "Corso rinominato")
    result = ContentCatalog.new(root: @root).import!

    course.reload
    assert_equal 0, result.created
    assert_equal "Corso rinominato", course.title
    assert_equal "published", course.publication_status
    assert_equal "public", course.publication_visibility
    assert_equal ["free"], course.access_modes
    assert_equal 1, course.contributions.count, "il contributo dell'autore non si duplica"
  end

  test "import never deletes contents missing from the YAML" do
    ContentCatalog.new(root: @root).import!
    FileUtils.rm_rf(@root.join("brands/autore-test"))

    ContentCatalog.new(root: @root).import!

    assert Content.exists?(key: "articolo-test")
  end

  test "dry run validates without saving" do
    result = ContentCatalog.new(root: @root).import!(dry_run: true)

    assert_equal 4, result.contents
    assert_equal 0, Content.count
  end

  test "rejects unknown parents, nodes and missing Markdown" do
    write "brands/progetto-test/courses/rotto/course.yml", <<~YAML
      contents:
        - id: orfano
          parent_id: inesistente
          format: chapter
          slug: orfano
          title: Orfano
          content_path: brands/progetto-test/courses/rotto/manca.md
        - id: senza-node
          format: course
          slug: senza-node
          title: Senza node
          publisher_node_slug: node-inesistente
    YAML

    error = assert_raises(ArgumentError) { ContentCatalog.new(root: @root).import! }

    assert_includes error.message, "parent_id sconosciuto inesistente"
    assert_includes error.message, "Markdown mancante"
    assert_includes error.message, "node sconosciuto node-inesistente"
    assert_equal 0, Content.count
  end

  test "warns when the author node has no profile" do
    @profile.update!(primary_node: nil)

    result = ContentCatalog.new(root: @root).import!

    assert_includes result.warnings, "corso-test: nessun profilo con node principale autore-test"
  end

  private

    def write(relative_path, body)
      path = @root.join(relative_path)
      FileUtils.mkdir_p(path.dirname)
      File.write(path, body)
    end
end
