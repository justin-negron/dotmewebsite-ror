class Project < ApplicationRecord
  MAX_MEDIA_URLS = 12

  # Kept in the schema for the previous release and dropped by a follow-up
  # migration with the next deploy. Ignoring it keeps this release's INSERTs
  # free of the column so that drop cannot break a running process.
  self.ignored_columns += [ "image_url" ]

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true
  validates :featured, inclusion: { in: [ true, false ] }
  validates :github_url, format: { with: HTTP_URL_FORMAT, allow_blank: true }
  validates :live_url, format: { with: HTTP_URL_FORMAT, allow_blank: true }
  validates :paper_url, format: { with: HTTP_URL_FORMAT, allow_blank: true }
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :media_urls, length: { maximum: MAX_MEDIA_URLS, too_long: "can have at most %{count} entries" }
  validate :media_urls_are_http_urls

  # Scopes
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(display_order: :asc, created_at: :desc) }
  scope :by_tech, ->(tech) { where("? = ANY(tech_stack)", tech) }

  # Callbacks
  before_validation :set_display_order, on: :create
  before_validation :normalize_media_urls

  # Instance methods
  def tech_stack_list
    tech_stack.join(", ")
  end

  private

  def set_display_order
    self.display_order ||= Project.maximum(:display_order).to_i + 1
  end

  # The admin form sends one URL per line, so drop blank lines and stray
  # whitespace before validating. Order is preserved: it is the slide order.
  def normalize_media_urls
    self.media_urls = Array(media_urls).map { |url| url.to_s.strip }.reject(&:blank?)
  end

  def media_urls_are_http_urls
    invalid = media_urls.reject { |url| url.match?(HTTP_URL_FORMAT) }
    return if invalid.empty?

    errors.add(:media_urls, "must all be http(s) URLs (invalid: #{invalid.join(', ')})")
  end
end
