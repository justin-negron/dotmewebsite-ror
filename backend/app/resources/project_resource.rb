class ProjectResource
  include Alba::Resource

  attributes :id, :title, :description, :tech_stack, :media_urls, :featured, :display_order

  attribute :github_url do |project|
    project.github_url.presence
  end

  attribute :live_url do |project|
    project.live_url.presence
  end

  attribute :paper_url do |project|
    project.paper_url.presence
  end

  attribute :created_at do |project|
    project.created_at&.iso8601
  end

  attribute :updated_at do |project|
    project.updated_at&.iso8601
  end
end
