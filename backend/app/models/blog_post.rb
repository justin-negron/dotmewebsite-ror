class BlogPost < ApplicationRecord
  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :content, presence: true

  # Scopes
  scope :published, -> { where(published: true).where.not(published_at: nil) }
  scope :draft, -> { where(published: false) }
  scope :recent, -> { order(published_at: :desc) }
  scope :by_tag, ->(tag) { where("? = ANY(tags)", tag) }

  # Callbacks
  before_validation :generate_slug, on: :create, if: -> { title.present? }
  before_validation :generate_excerpt, if: -> { excerpt.blank? && content.present? }
  before_save :set_published_at, if: -> { published_changed? && published? }

  # Instance methods
  def increment_view_count!
    increment!(:view_count)
  end

  def reading_time
    words_per_minute = 200
    word_count = content.split.size
    (word_count / words_per_minute.to_f).ceil
  end

  def tags_list
    tags.join(", ")
  end

  private

  def generate_slug
    return if slug.present?
    
    self.slug = title.parameterize
    
    # Handle duplicates
    if BlogPost.exists?(slug: slug)
      counter = 1
      loop do
        new_slug = "#{slug}-#{counter}"
        break self.slug = new_slug unless BlogPost.exists?(slug: new_slug)
        counter += 1
      end
    end
  end

  def generate_excerpt
    # Take first 160 characters of content
    self.excerpt = content.truncate(160, separator: ' ', omission: '...')
  end

  def set_published_at
    self.published_at = Time.current # if published? (redundant)
  end
end