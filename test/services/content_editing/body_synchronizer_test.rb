require "test_helper"

module ContentEditing
  class BodySynchronizerTest < ActiveSupport::TestCase
    setup do
      user = User.create!(email_address: "sync@example.test", password: "password123", password_confirmation: "password123")
      profile = user.create_profile!(display_name: "Sync", username: "sync")
      role = RoleAssignment.create!(profile:, role: :creator_of_worlds)
      node = Node.create!(title: "Nodo", slug: "sync-node", role_assignment: role)
      @content = Content.create!(node:, key: "sync-content", slug: "sync", format: "post", title: "Sync")
      @sync = BodySynchronizer.new(@content)
    end

    test "markdown initializes Lexxy and both checksums" do
      @sync.import_markdown!("# Titolo\n\nTesto **forte**.")

      assert_equal "clean", @content.sync_status
      assert_equal "markdown", @content.editor
      assert_includes @content.body.to_s, "Titolo"
      assert @content.markdown_checksum.present?
      assert @content.lexxy_checksum.present?
    end

    test "Lexxy regenerates markdown when markdown is unchanged" do
      @sync.import_markdown!("Testo iniziale")
      @sync.import_lexxy!("<h2>Nuovo titolo</h2><p>Testo Lexxy</p>")

      assert_equal "clean", @content.sync_status
      assert_equal "lexxy", @content.editor
      assert_includes @content.body_md, "## Nuovo titolo"
      assert_includes @content.body_md, "Testo Lexxy"
    end

    test "concurrent markdown and Lexxy changes create a conflict without losing either" do
      @sync.import_markdown!("Versione comune")
      @content.update_column(:body_md, "Markdown modificato localmente")

      @sync.import_lexxy!("<p>Lexxy modificato sul sito</p>")

      assert_equal "conflict", @content.sync_status
      assert_equal "Markdown modificato localmente", @content.body_md
      assert_includes @content.body.to_s, "Lexxy modificato sul sito"
    end

    test "explicit resolution with Lexxy synchronizes both representations" do
      @sync.import_markdown!("Versione comune")
      @content.update_column(:body_md, "Markdown divergente")
      @sync.import_lexxy!("<p>Lexxy definitivo</p>")

      @sync.resolve_with_lexxy!

      assert_equal "clean", @content.sync_status
      assert_equal "Lexxy definitivo", @content.body_md
    end
  end
end
