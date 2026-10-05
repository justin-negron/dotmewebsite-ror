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
    
    it 'raises error on transient failure to trigger retry' do
      allow(ContactMailer).to receive(:new_contact_notification)
        .and_raise(Net::ReadTimeout.new('Timeout'))

      expect {
        described_class.new.perform(contact.id)
      }.to raise_error(Net::ReadTimeout)
    end

    it 'raises error on permanent failure for discard' do
      allow(ContactMailer).to receive(:new_contact_notification)
        .and_raise(StandardError.new('Email failed'))

      expect {
        described_class.new.perform(contact.id)
      }.to raise_error(StandardError, 'Email failed')
    end
  end
  
  describe 'retry and discard handling' do
    let!(:contact) { create(:contact) }

    before { clear_enqueued_jobs }

    it 're-enqueues the job on a transient SMTP error' do
      allow(ContactMailer).to receive(:new_contact_notification)
        .and_raise(Net::ReadTimeout)

      expect {
        described_class.perform_now(contact.id)
      }.to have_enqueued_job(described_class).with(contact.id)
    end

    it 'discards and logs on a permanent error' do
      allow(ContactMailer).to receive(:new_contact_notification)
        .and_raise(StandardError, 'Email failed')
      allow(Rails.logger).to receive(:error)

      expect {
        described_class.perform_now(contact.id)
      }.not_to have_enqueued_job(described_class)
      expect(Rails.logger).to have_received(:error)
        .with(/Discarding job\. contact_id=#{contact.id} error=StandardError: Email failed/)
    end
  end

  describe 'queue configuration' do
    it 'queues to mailers queue' do
      expect(EmailNotificationJob.new.queue_name).to eq('mailers')
    end
  end
end