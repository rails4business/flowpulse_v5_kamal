# Lexxy 0.9.x installs these extensions from a `to_prepare` callback on
# Rails 8.0/8.1. Register them explicitly as well so FormBuilder instances
# created before that callback still expose the opt-in Lexxy helper.
require "lexxy/form_builder"
require "lexxy/form_helper"
require "lexxy/rich_text_area_tag"
require "lexxy/action_text_tag"

Rails.application.config.to_prepare do
  extensions = {
    ActionText::TagHelper => Lexxy::TagHelper,
    ActionView::Helpers::FormHelper => Lexxy::FormHelper,
    ActionView::Helpers::FormBuilder => Lexxy::FormBuilder,
    ActionView::Helpers::Tags::ActionText => Lexxy::ActionTextTag
  }

  extensions.each do |target, extension|
    target.prepend(extension) unless target < extension
  end
end
