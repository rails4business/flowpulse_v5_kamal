class PasswordResetRequest < ApplicationRecord
  belongs_to :user

  scope :pending, -> { where(fulfilled_at: nil) }
  scope :recent_first, -> { order(requested_at: :desc) }

  def pending?
    fulfilled_at.nil?
  end
end
