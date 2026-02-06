class BlogPostResource
  include Alba::Resource

  attributes :id, :title, :slug, :content, :published, :tags, :view_count

  attribute :reading_time do |post|
    post.reading_time
  end

  attribute :excerpt do |post|
    post.excerpt.presence || post.content.truncate(160, separator: ' ', omission: '...')
  end

  attribute :published_at do |post|
    post.published_at&.iso8601
  end

  attribute :created_at do |post|
    post.created_at&.iso8601
  end

  attribute :updated_at do |post|
    post.updated_at&.iso8601
  end
end
