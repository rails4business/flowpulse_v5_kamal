class RegistrationMailer < ApplicationMailer
  def verify_email(verification, raw_token, confirmation_url)
    @verification = verification
    @user = verification.user
    @domain = verification.requested_domain
    @raw_token = raw_token
    @confirmation_url = confirmation_url

    brand_name = @domain&.site_title.presence || @domain&.display_hostname || "FlowPulse"
    mail from: authentication_sender_for(@domain),
      to: @user.email_address,
      subject: "Conferma il tuo accesso a #{brand_name}"
  end
end
