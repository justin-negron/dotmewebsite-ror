class ExperienceSerializer < ActiveModel::Serializer
  attributes :id,
             :company,
             :position,
             :start_date,
             :end_date,
             :description,
             :technologies,
             :display_order,
             :current,
             :duration,
             :created_at,
             :updated_at
  
  # Include custom method from model
  def current
    object.current?
  end
  
  # Include formatted duration from model
  def duration
    object.duration
  end
  
  # Format dates
  def start_date
    object.start_date&.iso8601
  end
  
  def end_date
    object.end_date&.iso8601
  end
  
  def created_at
    object.created_at&.iso8601
  end
  
  def updated_at
    object.updated_at&.iso8601
  end
end