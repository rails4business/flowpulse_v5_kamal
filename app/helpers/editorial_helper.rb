module EditorialHelper
  include MarkdownHelper

  EDITORIAL_MARKDOWN_CLASSES = <<~CLASSES.squish.freeze
    editorial-markdown
    [&_p+p]:mt-4
    [&_strong]:font-black
    [&_em]:italic
    [&_a]:font-bold [&_a]:underline [&_a]:underline-offset-2
    [&_ul]:mt-4 [&_ul]:list-disc [&_ul]:space-y-2 [&_ul]:pl-6
    [&_ol]:mt-4 [&_ol]:list-decimal [&_ol]:space-y-2 [&_ol]:pl-6
  CLASSES

  def editorial_markdown(text)
    markdown(text)
  end

  def editorial_inline_markdown(text)
    inline_markdown(text)
  end

  def editorial_markdown_classes
    EDITORIAL_MARKDOWN_CLASSES
  end
end
