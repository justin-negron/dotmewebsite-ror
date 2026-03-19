module AuthHelper
  def auth_headers(admin = nil)
    admin ||= create(:admin)
    token = JwtService.encode_access_token(admin)
    { 'Authorization' => "Bearer #{token}" }
  end
end
