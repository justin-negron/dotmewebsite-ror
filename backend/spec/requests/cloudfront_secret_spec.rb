require 'rails_helper'

# Caddy rejects secretless requests first, so Rails only sees them when the two
# secrets disagree, for example mid-rotation.
RSpec.describe 'CloudFront secret through the full stack', type: :request do
  before do
    allow(Rails.env).to receive(:production?).and_return(true)
    stub_const('ENV', ENV.to_h.merge('CLOUDFRONT_SECRET' => 's3cret'))
  end

  it 'answers a HEAD without the secret with 403 and an empty body' do
    head '/api/v1/projects'

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to eq('')
  end

  it 'gives two rejected requests their own request ids' do
    _, first_headers, _ = Rails.application.call(Rack::MockRequest.env_for('/api/v1/projects'))
    _, second_headers, _ = Rails.application.call(Rack::MockRequest.env_for('/api/v1/projects'))

    expect(first_headers['x-request-id']).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    expect(first_headers['x-request-id']).not_to eq(second_headers['x-request-id'])
  end
end
