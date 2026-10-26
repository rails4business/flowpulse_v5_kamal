require "test_helper"

class PublicSubmissionRegistryTest < ActiveSupport::TestCase
  test "every anonymous mutating application route declares its protection" do
    registry = YAML.safe_load_file(Rails.root.join("config/public_submissions.yml"))
    public_entries = registry.fetch("public_submissions")
    protected_entries = registry.fetch("authenticated_or_token_protected")
    missing = []
    mismatched = []

    Rails.application.routes.routes.each do |route|
      next unless route.verb.to_s.match?(/POST|PATCH|PUT|DELETE/)

      controller_path = route.defaults[:controller].to_s
      action = route.defaults[:action].to_s
      next if controller_path.blank? || action.blank?

      controller = "#{controller_path.camelize}Controller".safe_constantize
      next unless controller&.<(ApplicationController)
      next unless controller.action_methods.include?(action)
      next unless controller.respond_to?(:unauthenticated_action?) && controller.unauthenticated_action?(action)

      key = "#{controller_path}##{action}"
      entry = public_entries[key]
      unless entry || protected_entries.key?(key)
        missing << key
        next
      end

      next unless entry

      configured_form_key = controller.public_submission_actions.dig(action, :form_key) if controller.respond_to?(:public_submission_actions)
      mismatched << "#{key} (registro: #{entry.fetch('form_key')}, controller: #{configured_form_key || 'assente'})" unless configured_form_key == entry.fetch("form_key")
    end

    assert_empty missing.uniq, "Endpoint anonimi mutanti non registrati: #{missing.uniq.join(', ')}"
    assert_empty mismatched.uniq, "Protezione dei moduli incoerente: #{mismatched.uniq.join(', ')}"
  end
end
