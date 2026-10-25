class PageView < ApplicationRecord
  # Blanked by migration 20261014000000 and dropped by a follow-up with the next
  # deploy. Ignoring it keeps this release's SQL free of the column so that drop
  # cannot break a running process.
  self.ignored_columns += [ "ip_address" ]

  # Validations
  validates :path, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_path, ->(path) { where(path: path) }
  scope :in_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Class methods
  def self.popular_pages(limit = 10)
    group(:path)
      .select("path, COUNT(*) as view_count")
      .order("view_count DESC")
      .limit(limit)
  end

  def self.views_by_date(days = 30)
    where("created_at >= ?", days.days.ago)
      .group("DATE(created_at)")
      .count
  end

  def self.unique_visitors(days = 30)
    where("created_at >= ?", days.days.ago)
      .distinct
      .count(:visitor_hash)
  end

  # Keyed with a secret derived from secret_key_base and salted by the day. The
  # key is what stops a table dump being brute-forced back to addresses (IPv4
  # is only 2^32 values); the day stops one visitor linking across days.
  def self.visitor_hash_for(ip, date = Date.current)
    key = Rails.application.key_generator.generate_key("page_view.visitor_hash")
    OpenSSL::HMAC.hexdigest("SHA256", key, "#{date}#{ip}")[0, 32]
  end

  def self.purge_older_than(days)
    days = Integer(days)
    raise ArgumentError, "retention must be at least 1 day, got #{days}" if days < 1

    where("created_at < ?", days.days.ago).in_batches.delete_all
  end

  # Instance methods
  def browser_name
    return "Unknown" if user_agent.blank?

    case user_agent
    when %r{Edge?/}
      "Edge"
    when %r{OPR/}
      "Opera"
    when /Chrome/
      "Chrome"
    when /Safari/
      "Safari"
    when /Firefox/
      "Firefox"
    else
      "Other"
    end
  end
end
