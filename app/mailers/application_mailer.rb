class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "FlowPulse Accesso <accesso@flowpulse.net>")
  layout "mailer"
end
