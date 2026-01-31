require 'rails_helper'

RSpec.describe EmailNotificationJob, type: :job do
  let(:contact) { create(:contact) }
  
  describe '#perform' do
    it 'sends notification email to site owner' do
      expect(ContactMailer).to receive(:new_contact_notification)
        .with(contact.id)
        .and_call_original
      
      described_class.new.perform(contact.id)
    end
    
    it 'sends confirmation email to visitor' do
      expect(ContactMailer).to receive(:submission_confirmation)
        .with(contact.id)
        .and_call_original
      
      described_class.new.perform(contact.id)
    end
    
    it 'sends both emails' do
      mailer_double = double('ContactMailer')
      allow(ContactMailer).to receive(:new_contact_notification)
        .and_return(mailer_double)
      allow(ContactMailer).to receive(:submission_confirmation)
        .and_return(mailer_double)
      allow(mailer_double).to receive(:deliver_now)
      
      described_class.new.perform(contact.id)
      
      expect(mailer_double).to have_received(:deliver_now).twice
    end
    
    it 'raises error on failure to trigger retry' do
      allow(ContactMailer).to receive(:new_contact_notification)
        .and_raise(StandardError.new('Email failed'))
      
      expect {
        described_class.new.perform(contact.id)
      }.to raise_error(StandardError, 'Email failed')
    end
    
    it 'logs errors' do
      allow(ContactMailer).to receive(:new_contact_notification)
        .and_raise(StandardError.new('Email failed'))
      allow(Rails.logger).to receive(:error)
      
      begin
        described_class.new.perform(contact.id)
      rescue StandardError
        # Expected
      end
      
      expect(Rails.logger).to have_received(:error)
        .with(/Failed to send email for contact #{contact.id}/)
    end
  end
  
  describe 'queue configuration' do
    it 'queues to mailers queue' do
      expect(EmailNotificationJob.new.queue_name).to eq('mailers')
    end
  end
end