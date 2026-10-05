require 'rails_helper'

RSpec.describe ContactMailer, type: :mailer do
  before do
    stub_const('ENV', ENV.to_h.merge(
      'MAILER_FROM' => 'notifications@example.com',
      'CONTACT_NOTIFY_TO' => 'owner@example.com'
    ))
  end

  describe '#new_contact_notification' do
    let(:contact) { create(:contact, name: 'John Doe', email: 'john@example.com', subject: 'Test Subject', message: 'Test message') }
    let(:mail) { ContactMailer.new_contact_notification(contact.id) }

    it 'goes to the owner from the site address, replying to the visitor' do
      expect(mail.subject).to eq('New Contact Form Submission: Test Subject')
      expect(mail.to).to eq(['owner@example.com'])
      expect(mail.from).to eq(['notifications@example.com'])
      expect(mail.reply_to).to eq(['john@example.com'])
    end

    it 'includes contact name in body' do
      expect(mail.body.encoded).to match('John Doe')
    end

    it 'includes contact email in body' do
      expect(mail.body.encoded).to match('john@example.com')
    end

    it 'includes contact message in body' do
      expect(mail.body.encoded).to match('Test message')
    end

    it 'includes subject in body' do
      expect(mail.body.encoded).to match('Test Subject')
    end
  end

  it 'does not email visitors' do
    expect(ContactMailer.action_methods).to contain_exactly('new_contact_notification')
  end
end
