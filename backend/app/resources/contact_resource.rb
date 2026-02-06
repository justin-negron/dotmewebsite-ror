class ContactResource
  include Alba::Resource

  attributes :id, :name, :email, :subject, :message, :status

  attribute :created_at do |contact|
    contact.created_at&.iso8601
  end
end
