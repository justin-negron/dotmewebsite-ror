class BlogPostSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :slug,
             :content,
             :excerpt,
             :published,
             :published_at,
             :tags,
             :view_count,
             :reading_time,
             :created_at,
             :updated_at
  
  # Include custom reading time calculation
  def reading_time
    object.reading_time
  end
  
  # Format dates
  def published_at
    object.published_at&.iso8601
  end
  
  def created_at
    object.created_at&.iso8601
  end
  
  def updated_at
    object.updated_at&.iso8601
  end
  
  # Generate excerpt if not present
  def excerpt
    object.excerpt.presence || object.content.truncate(160, separator: ' ', omission: '...')
  end
end