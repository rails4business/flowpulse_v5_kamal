require "test_helper"

module CreatorWorld
  class ContentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = create_user("creator-contents@example.com")
      @assignment = RoleAssignment.create!(profile: @user.profile, role: :ideatore)
      @user.update!(active_role: :ideatore, current_role_assignment: @assignment)
      @node = Node.create!(title: "Lezione", slug: "lezione-editor", role_assignment: @assignment)
      @content = Content.create!(node: @node, key: "lezione-editor-intro", slug: "intro", format: "post",
        role: "introduction", title: "Introduzione")
      @publication = @content.publications.create!(key: "video", platform: "youtube", format: "video",
        title: "Video introduttivo", url: "https://youtube.com/watch?v=test")
      @node.update!(show_content: @content)
      sign_in(@user)
    end

    test "editor shows metadata markdown Lexxy and publication choice" do
      get edit_creator_world_role_assignment_node_content_url(@assignment, @node, @content)

      assert_response :success
      assert_select "textarea[name='content[body_md]']"
      assert_select "lexxy-editor[name='content[body]']"
      assert_select "select[name='content[show_publication_id]'] option[value='#{@publication.id}']"
      assert_select "button[value='save_markdown']"
      assert_select "button[value='save_lexxy']"
    end

    test "saving markdown updates Lexxy and metadata" do
      patch creator_world_role_assignment_node_content_url(@assignment, @node, @content), params: {
        sync_action: "save_markdown",
        content: {
          title: "Nuova introduzione", role: "introduction", placement: "after_body", position: 0,
          publication_status: "published", publication_visibility: "public",
          show_publication_id: @publication.id, body_md: "# Corpo aggiornato"
        }
      }

      assert_redirected_to edit_creator_world_role_assignment_node_content_url(@assignment, @node, @content)
      @content.reload
      assert_equal "Nuova introduzione", @content.title
      assert_equal @publication, @content.show_publication
      assert_equal "# Corpo aggiornato", @content.body_md
      assert_includes @content.body.to_s, "Corpo aggiornato"
      assert_equal "clean", @content.sync_status
    end

    test "cannot edit an unrelated Content" do
      other_node = Node.create!(title: "Altro", slug: "altro-editor", role_assignment: @assignment)
      other = Content.create!(node: other_node, key: "altro-editor-content", slug: "intro", format: "post", title: "Altro")

      get edit_creator_world_role_assignment_node_content_url(@assignment, @node, other)

      assert_response :not_found
    end

    private

      def create_user(email)
        User.create!(email_address: email, password: "password123", password_confirmation: "password123").tap do |user|
          user.create_profile!(display_name: email.split("@").first)
        end
      end

      def sign_in(user)
        post session_url, params: { email_address: user.email_address, password: "password123" }
      end
  end
end
