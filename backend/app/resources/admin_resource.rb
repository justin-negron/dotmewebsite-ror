class AdminResource
  include Alba::Resource

  attributes :id, :email

  attribute :created_at do |admin|
    admin.created_at&.iso8601
  end
end
