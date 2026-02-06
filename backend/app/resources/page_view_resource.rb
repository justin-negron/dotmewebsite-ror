class PageViewResource
  include Alba::Resource

  attributes :id, :path

  attribute :browser_name do |page_view|
    page_view.browser_name
  end

  attribute :created_at do |page_view|
    page_view.created_at&.iso8601
  end
end
