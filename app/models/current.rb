class Current < ActiveSupport::CurrentAttributes
  attribute :session, :domain
  delegate :user, to: :session, allow_nil: true
end
