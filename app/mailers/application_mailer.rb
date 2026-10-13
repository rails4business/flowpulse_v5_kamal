class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "FlowPulse Accesso <accesso@flowpulse.net>")
  layout "mailer"

  private
    def authentication_sender_for(domain)
      domain&.canonical_domain_record&.authentication_sender.presence ||
        ENV.fetch("MAILER_FROM", "FlowPulse Accesso <accesso@flowpulse.net>")
    end
end
