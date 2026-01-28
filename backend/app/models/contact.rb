class Contact < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { minimum: 10 }

  # Enums
  enum status: {
    new: 'new',
    read: 'read',
    archived: 'archived'
  }, _prefix: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(status: 'new') }

  # Callbacks
  after_create :send_notification

  # Instance methods
  def mark_as_read!
    update(status: 'read')
  end

  def mark_as_archived!
    update(status: 'archived')
  end

  private

  def send_notification
    # Queue email job to send in background
    EmailNotificationJob.perform_later(self.id)
  end
end