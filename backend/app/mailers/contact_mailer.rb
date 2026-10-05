class ContactMailer < ApplicationMailer
  # Notify the site owner of a new contact form submission.
  # Visitors are never emailed: their address is unverified, so a confirmation
  # would let anyone send mail to arbitrary addresses through this site.
  def new_contact_notification(contact_id)
    @contact = Contact.find_by(id: contact_id)
    return unless @contact

    mail(
      to: ENV.fetch('CONTACT_NOTIFY_TO', 'owner@example.com'),
      subject: "New Contact Form Submission: #{@contact.subject || 'No Subject'}",
      reply_to: @contact.email
    )
  end
end
