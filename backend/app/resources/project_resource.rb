class ProjectResource
  include Alba::Resource

  attributes :id, :title, :description, :tech_stack, :featured, :display_order

  attribute :github_url do |project|
    project.github_url.presence
  end

  attribute :live_url do |project|
    project.live_url.presence
  end

  attribute :image_url do |project|
    project.image_url.presence
  end

  attribute :created_at do |project|
    project.created_at&.iso8601
  end

  attribute :updated_at do |project|
    project.updated_at&.iso8601
  end
end
