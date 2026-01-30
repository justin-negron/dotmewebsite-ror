class EmailNotificationJob < ApplicationJob
  queue_as :mailers
  
  # Retry with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  
  def perform(contact_id)
    # Send notification to site owner
    ContactMailer.new_contact_notification(contact_id).deliver_now
    
    # Send confirmation to visitor
    ContactMailer.submission_confirmation(contact_id).deliver_now
  rescue StandardError => e
    # Log error but don't fail the job
    Rails.logger.error "Failed to send email for contact #{contact_id}: #{e.message}"
    raise e  # Re-raise to trigger retry
  end
end