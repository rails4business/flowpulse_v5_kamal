require "test_helper"

class PublicSubmissionSecurityTest < ActiveSupport::TestCase
  test "accepts a signed token only for its form and host" do
    issued_at = Time.zone.parse("2026-10-25 10:00:00")
    token = PublicSubmissionSecurity.generate_token(
      form_key: "contact",
      host: "Example.org:443",
      issued_at: issued_at
    )

    assert PublicSubmissionSecurity.verify_token(
      token, form_key: "contact", host: "example.org", now: issued_at + 4.seconds,
      minimum_fill_time: 3.seconds
    )
    assert_not PublicSubmissionSecurity.verify_token(
      token, form_key: "another-form", host: "example.org", now: issued_at + 4.seconds,
      minimum_fill_time: 3.seconds
    )
    assert_not PublicSubmissionSecurity.verify_token(
      token, form_key: "contact", host: "other.example", now: issued_at + 4.seconds,
      minimum_fill_time: 3.seconds
    )
  end

  test "rejects submissions that are too fast or expired" do
    issued_at = Time.zone.parse("2026-10-25 10:00:00")
    token = PublicSubmissionSecurity.generate_token(form_key: "contact", host: "example.org", issued_at: issued_at)

    assert_not PublicSubmissionSecurity.verify_token(
      token, form_key: "contact", host: "example.org", now: issued_at + 1.second,
      minimum_fill_time: 3.seconds
    )
    assert_not PublicSubmissionSecurity.verify_token(
      token, form_key: "contact", host: "example.org", now: issued_at + 3.hours,
      minimum_fill_time: 3.seconds
    )
  end

  test "uses the standard profile by default and the canonical domain profile for aliases" do
    primary = Domain.create!(hostname: "secure.example", security_profile: "sensitive")
    alias_domain = Domain.create!(hostname: "www.secure.example", canonical_host: primary.hostname)

    assert_equal "standard", PublicSubmissionSecurity.profile_for(nil).fetch(:key)
    assert_equal "sensitive", PublicSubmissionSecurity.profile_for(alias_domain).fetch(:key)
    assert_equal 3, PublicSubmissionSecurity.profile_for(alias_domain).fetch(:per_ip)
  end
end
