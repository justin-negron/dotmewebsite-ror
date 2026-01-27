class ProjectSerializer < ActiveModel::Serializer
  attributes :id, 
             :title, 
             :description, 
             :tech_stack,
             :github_url,
             :live_url,
             :image_url,
             :featured,
             :display_order,
             :created_at,
             :updated_at
  
  # Format dates as ISO 8601
  def created_at
    object.created_at&.iso8601
  end
  
  def updated_at
    object.updated_at&.iso8601
  end
  
  # Only include URLs if they exist
  def github_url
    object.github_url.presence
  end
  
  def live_url
    object.live_url.presence
  end
  
  def image_url
    object.image_url.presence
  end
end