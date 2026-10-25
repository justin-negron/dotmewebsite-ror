require 'rails_helper'

RSpec.describe EmailNotificationJob, type: :job do
  let(:contact) { create(:contact) }

  before { ActionMailer::Base.deliveries.clear }

  describe '#perform' do
    it 'delivers one notification that replies to the visitor' do
      described_class.new.perform(contact.id)

      expect(ActionMailer::Base.deliveries.map(&:reply_to)).to eq([ [ contact.email ] ])
    end

    it 'sends nothing and discards nothing when the contact was deleted before it ran' do
      contact.destroy
      allow(Rails.logger).to receive(:error).and_call_original

      described_class.perform_now(contact.id)

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(Rails.logger).not_to have_received(:error).with(/Discarding job/)
    end

    it 'sends only the owner notification' do
      delivery = double('MessageDelivery', deliver_now: true)
      allow(ContactMailer).to receive(:new_contact_notification).and_return(delivery)

      described_class.new.perform(contact.id)

      expect(delivery).to have_received(:deliver_now).once
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

    it 're-enqueues the job when SES throttles' do
      allow(ContactMailer).to receive(:new_contact_notification)
        .and_raise(Aws::SESV2::Errors::TooManyRequestsException.new(nil, 'Slow down'))

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
