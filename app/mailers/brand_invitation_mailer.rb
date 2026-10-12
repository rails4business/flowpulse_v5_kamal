class BrandInvitationMailer < ApplicationMailer
  def invite(invitation, raw_token, invitation_url)
    @invitation = invitation
    @raw_token = raw_token
    @invitation_url = invitation_url
    @domain = invitation.source_domain

    brand_name = @domain&.site_title.presence || invitation.brand_node.title
    mail to: invitation.email_address, subject: "Sei stato invitato in #{brand_name}"
  end
end
