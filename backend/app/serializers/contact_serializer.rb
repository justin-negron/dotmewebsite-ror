class ContactSerializer < ActiveModel::Serializer
  attributes :id,
             :name,
             :email,
             :subject,
             :message,
             :status,
             :created_at
  
  # Format date
  def created_at
    object.created_at&.iso8601
  end
  
  # Note: We typically don't expose contact details via public API
  # This serializer is mainly for admin use
end