module ComponentsHelper
  BUILDER_MARKDOWN_ROOT = Rails.root.join("config/data/posturacorretta").freeze

  def builder_markdown(content_path)
    path = BUILDER_MARKDOWN_ROOT.join(content_path.to_s).cleanpath
    root = "#{BUILDER_MARKDOWN_ROOT.cleanpath}#{File::SEPARATOR}"

    return "".html_safe unless path.to_s.start_with?(root)
    return "".html_safe unless path.file? && path.extname.downcase == ".md"

    markdown(path.read)
  end
end
