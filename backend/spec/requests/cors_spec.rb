require 'rails_helper'

# The CORS middleware reads its origin list once at boot, so the request specs
# exercise the non-development rule (what the test and production environments
# run with) and the development pattern is checked directly.
RSpec.describe 'CORS', type: :request do
  let(:frontend_origin) { ENV.fetch('FRONTEND_URL', 'https://justinnegron.dev') }

  def preflight(origin)
    options '/api/v1/projects',
            headers: {
              'Origin' => origin,
              'Access-Control-Request-Method' => 'GET'
            }
  end

  it 'answers preflight from the configured frontend origin with credentials' do
    preflight(frontend_origin)

    expect(response.headers['Access-Control-Allow-Origin']).to eq(frontend_origin)
    expect(response.headers['Access-Control-Allow-Credentials']).to eq('true')
  end

  it 'reflects the configured frontend origin on simple GETs' do
    get '/api/v1/projects', headers: { 'Origin' => frontend_origin }

    expect(response).to have_http_status(:ok)
    expect(response.headers['Access-Control-Allow-Origin']).to eq(frontend_origin)
  end

  it 'ignores every other origin outside development' do
    [ 'http://localhost:65000', 'https://evil.example.com' ].each do |origin|
      preflight(origin)
      expect(response.headers['Access-Control-Allow-Origin']).to be_nil, "expected #{origin} to be rejected"
    end
  end

  describe 'development origin pattern' do
    it 'is what development uses' do
      allow(Rails.env).to receive(:development?).and_return(true)

      expect(CorsOrigins.allowed).to eq(CorsOrigins::DEVELOPMENT)
    end

    it 'accepts the Vite dev server on any localhost port' do
      %w[http://localhost:5173 http://localhost:5174 http://127.0.0.1:4173].each do |origin|
        expect(origin).to match(CorsOrigins::DEVELOPMENT)
      end
    end

    it 'rejects anything that is not plain localhost' do
      %w[
        http://evil.example.com:5173
        http://localhost.evil.com:5173
        http://localhost:5173.evil.com
        http://localhost
      ].each do |origin|
        expect(origin).not_to match(CorsOrigins::DEVELOPMENT)
      end
    end
  end
end
