class Current < ActiveSupport::CurrentAttributes
  attribute :session, :domain, :access_context
  delegate :user, to: :session, allow_nil: true
end
