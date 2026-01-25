class PageView < ApplicationRecord
  # Validations
  validates :path, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_path, ->(path) { where(path: path) }
  scope :in_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Class methods
  def self.popular_pages(limit = 10)
    group(:path)
      .select('path, COUNT(*) as view_count')
      .order('view_count DESC')
      .limit(limit)
  end

  def self.views_by_date(days = 30)
    where('created_at >= ?', days.days.ago)
      .group("DATE(created_at)")
      .count
  end

  def self.unique_visitors(days = 30)
    where('created_at >= ?', days.days.ago)
      .distinct
      .count(:ip_address)
  end

  # Instance methods
  def browser_name
    return 'Unknown' if user_agent.blank?
    
    case user_agent
    when /Chrome/
      'Chrome'
    when /Safari/
      'Safari'
    when /Firefox/
      'Firefox'
    when /Edge/
      'Edge'
    else
      'Other'
    end
  end
end