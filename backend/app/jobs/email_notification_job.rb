require 'net/smtp'

class EmailNotificationJob < ApplicationJob
  queue_as :mailers

  # ActiveJob checks handlers bottom-up, so this catch-all must be declared
  # before retry_on or it would swallow the transient errors below.
  discard_on StandardError do |job, exception|
    Rails.logger.error(
      "[EmailNotificationJob] Discarding job. " \
      "contact_id=#{job.arguments.first} error=#{exception.class}: #{exception.message}"
    )
  end

  retry_on Net::SMTPServerBusy, Net::OpenTimeout, Net::ReadTimeout,
           wait: :polynomially_longer, attempts: 3

  def perform(contact_id)
    # Send notification to site owner
    ContactMailer.new_contact_notification(contact_id).deliver_now

    # Send confirmation to visitor
    ContactMailer.submission_confirmation(contact_id).deliver_now
  end
end
