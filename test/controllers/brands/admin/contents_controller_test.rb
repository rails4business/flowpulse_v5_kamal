require "test_helper"

class Brands::Admin::ContentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "brand-contents-owner@example.com", password: "password123", password_confirmation: "password123")
    @profile = @owner.create_profile!(display_name: "Autrice", username: "autrice_contenuti")
    role = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
    @professional = Node.create!(role_assignment: role, title: "Autrice", slug: "autrice-contenuti", node_type: "professional", status: "published")
    @profile.update!(primary_node: @professional)
    Domain.create!(hostname: "autrice-contenuti.test", node: @professional, role_assignment: role, active: true)
    @project = Node.create!(role_assignment: role, title: "Progetto", slug: "progetto-contenuti", status: "published")
    Domain.create!(hostname: "progetto-contenuti.test", node: @project, role_assignment: role, active: true)
    @article = Content.create!(node: @professional, key: "articolo-autrice", slug: "articolo-autrice", format: "post", title: "Articolo dell'autrice", profile: @profile)
    @course = Content.create!(node: @project, key: "corso-progetto", slug: "corso-progetto", format: "course", title: "Corso del progetto", profile: @profile)
    @stranger = Content.create!(node: @project, key: "corso-altrui", slug: "corso-altrui", format: "course", title: "Corso di altri")
  end

  test "the owner's brand lists its contents and the owner's contents in other brands with their domain" do
    sign_in

    get brand_admin_contents_url(@professional.slug)

    assert_response :success
    assert_select ".brand-admin-nav a[aria-current='page']", text: "Contenuti"
    assert_select "tr##{ActionView::RecordIdentifier.dom_id(@article)} td", text: "autrice-contenuti.test"
    assert_select "tr##{ActionView::RecordIdentifier.dom_id(@course)} td", text: "progetto-contenuti.test"
    assert_select "td", text: /Corso di altri/, count: 0
  end

  test "contents are filtered by domain and type" do
    sign_in

    get brand_admin_contents_url(@professional.slug, dominio: "progetto-contenuti.test", tipo: "course")

    assert_select "td", text: /Corso del progetto/
    assert_select "td", text: /Articolo dell'autrice/, count: 0
    assert_select "select[name=dominio] option[selected]", text: "progetto-contenuti.test"
  end

  test "publication is changed directly and the publication date is set when missing" do
    sign_in

    patch brand_admin_content_url(@professional.slug, @course), params: { content: { publication_status: "published", publication_visibility: "public", access_modes: [ "", "free" ] } }

    @course.reload
    assert @course.published_for_public?
    assert @course.published_at.present?
    assert_equal [ "free" ], @course.access_modes
  end

  test "a content of another brand not owned by the brand owner cannot be changed from here" do
    sign_in

    patch brand_admin_content_url(@professional.slug, @stranger), params: { content: { publication_status: "published" } }

    assert_response :not_found
    assert_equal "draft", @stranger.reload.publication_status
  end

  private

    def sign_in
      post session_url, params: { email_address: @owner.email_address, password: "password123" }
    end
end
