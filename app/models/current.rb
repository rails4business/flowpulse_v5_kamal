class Current < ActiveSupport::CurrentAttributes
  attribute :session, :dedicated_domain
  delegate :user, to: :session, allow_nil: true
end
