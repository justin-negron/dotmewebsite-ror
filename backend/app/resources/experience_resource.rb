class ExperienceResource
  include Alba::Resource

  attributes :id, :company, :position, :description, :technologies, :display_order, :experience_type

  attribute :current do |experience|
    experience.current?
  end

  attribute :duration do |experience|
    experience.duration
  end

  attribute :start_date do |experience|
    experience.start_date&.iso8601
  end

  attribute :end_date do |experience|
    experience.end_date&.iso8601
  end

  attribute :created_at do |experience|
    experience.created_at&.iso8601
  end

  attribute :updated_at do |experience|
    experience.updated_at&.iso8601
  end
end
