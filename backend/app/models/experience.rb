class Experience < ApplicationRecord
  # Validations
  validates :company, presence: true, length: { maximum: 255 }
  validates :position, presence: true, length: { maximum: 255 }
  validates :start_date, presence: true
  validate :end_date_after_start_date

  # Scopes
  scope :ordered, -> { order(start_date: :desc) }
  scope :current, -> { where(end_date: nil) }
  scope :past, -> { where.not(end_date: nil) }

  # Callbacks
  before_validation :set_display_order, on: :create

  # Instance methods
  def current?
    end_date.nil?
  end

  def duration
    start_year = start_date.year
    end_year = end_date&.year || Date.current.year
    
    if start_year == end_year
      start_date.strftime("%B %Y")
    else
      end_str = current? ? "Present" : end_date.strftime("%B %Y")
      "#{start_date.strftime('%B %Y')} - #{end_str}"
    end
  end

  def technologies_list
    technologies.join(", ")
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    
    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def set_display_order
    self.display_order ||= Experience.maximum(:display_order).to_i + 1
  end
end