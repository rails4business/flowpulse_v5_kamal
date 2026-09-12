require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "adds an ImageKit transformation without discarding existing query parameters" do
    source = "https://ik.imagekit.io/posturacorretta/example.png?updatedAt=1"

    assert_equal "#{source}&tr=w-480,c-at_max,q-80,f-auto", imagekit_url(source, width: 480)
  end

  test "leaves non ImageKit images unchanged" do
    source = "https://example.org/example.png"

    assert_equal source, imagekit_url(source, width: 480)
  end

  test "builds a responsive ImageKit image" do
    tag = imagekit_image_tag(
      "https://ik.imagekit.io/posturacorretta/example.png",
      alt: "Esempio",
      widths: [480, 768],
      sizes: "100vw",
      class_name: "cover",
      loading: "eager",
      fetchpriority: "high",
      width: 480,
      height: 240
    )

    assert_includes tag, "srcset="
    assert_includes tag, "480w"
    assert_includes tag, "768w"
    assert_includes tag, "fetchpriority=\"high\""
    assert_includes tag, "width=\"480\""
    assert_includes tag, "height=\"240\""
  end
end
