class PageViewSerializer < ActiveModel::Serializer
  attributes :id,
             :path,
             :browser_name,
             :created_at
  
  # Include custom browser detection
  def browser_name
    object.browser_name
  end
  
  # Format date
  def created_at
    object.created_at&.iso8601
  end
  
  # Note: We don't expose IP address or full user agent for privacy
end