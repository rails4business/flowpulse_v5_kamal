class NodeContent < ApplicationRecord
  belongs_to :node, inverse_of: :content

  validates :node, presence: true
  validates :node_id, uniqueness: true
  validates :editor, presence: true
  validates :format, presence: true

  before_validation :set_defaults

  private

  def set_defaults
    self.editor = "markdown" if editor.blank?
    self.format = "markdown" if format.blank?
    self.body_json = {} if body_json.blank?
    self.data = {} if data.blank?
  end
end
