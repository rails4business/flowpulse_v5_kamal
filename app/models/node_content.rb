class NodeContent < ApplicationRecord
  belongs_to :node, inverse_of: :content
  has_rich_text :body

  validates :node, presence: true
  validates :node_id, uniqueness: true
  validates :editor, presence: true
  validates :format, presence: true

  before_validation :set_defaults
  before_validation :sync_lexxy_derivatives, if: :lexxy_content?

  def prepare_lexxy_body!
    return if body.present?

    self.body = body_html.presence || NodeContent::MarkdownToHtml.call(body_md)
  end

  private

  def set_defaults
    self.editor = "markdown" if editor.blank?
    self.format = "markdown" if format.blank?
    self.body_json = {} if body_json.blank?
    self.data = {} if data.blank?
  end

  def lexxy_content?
    editor == "lexxy"
  end

  def sync_lexxy_derivatives
    self.body_html = body.to_s
    self.body_md = NodeContent::HtmlToMarkdown.call(body_html)
    self.format = "html"
  end
end
