class ContactMailer < ApplicationMailer
  default from: ENV.fetch('FROM_EMAIL', 'justinnegron174@gmail.com')
  
  # Send notification to site owner when someone submits contact form
  def new_contact_notification(contact_id)
    @contact = Contact.find(contact_id)
    
    mail(
      to: ENV.fetch('FROM_EMAIL', 'justinnegron174@gmail.com'),
      subject: "New Contact Form Submission: #{@contact.subject || 'No Subject'}",
      reply_to: @contact.email
    )
  end
  
  # Send confirmation to person who submitted the form
  def submission_confirmation(contact_id)
    @contact = Contact.find(contact_id)
    
    mail(
      to: @contact.email,
      subject: 'Thanks for reaching out!'
    )
  end
end