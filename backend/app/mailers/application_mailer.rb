class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch('MAILER_FROM', 'notifications@justinnegron.dev') }
  layout "mailer"
end
