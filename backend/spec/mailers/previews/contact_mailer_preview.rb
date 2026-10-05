# Preview all emails at http://localhost:3000/rails/mailers/contact_mailer
class ContactMailerPreview < ActionMailer::Preview
  # Preview new contact notification email
  # Visit: http://localhost:3000/rails/mailers/contact_mailer/new_contact_notification
  def new_contact_notification
    contact = Contact.first || Contact.new(
      name: 'John Doe',
      email: 'john@example.com',
      subject: 'Inquiry about your services',
      message: 'Hi! I came across your portfolio and was impressed by your work. I would like to discuss a potential project with you.'
    )
    ContactMailer.new_contact_notification(contact.id || 1)
  end
end
