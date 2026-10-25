require 'rails_helper'

RSpec.describe CloudfrontSecretMiddleware do
  let(:app) { ->(_env) { [ 200, {}, [ 'ok' ] ] } }
  let(:middleware) { described_class.new(app) }
  let(:passed) { [ 200, {}, [ 'ok' ] ] }
  let(:forbidden) { [ 403, { 'content-type' => 'application/json' }, [ '{"error":"Forbidden"}' ] ] }

  def call(path, headers = {})
    middleware.call(Rack::MockRequest.env_for(path, headers))
  end

  it 'passes every request through outside production' do
    expect(call('/api/v1/admin/projects')).to eq(passed)
  end

  context 'in production' do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
      stub_const('ENV', ENV.to_h.merge('CLOUDFRONT_SECRET' => 's3cret'))
    end

    it 'rejects a request with the wrong secret' do
      expect(call('/api/v1/projects', 'HTTP_X_CLOUDFRONT_SECRET' => 'wrong')).to eq(forbidden)
    end

    it 'rejects a request with no secret header' do
      expect(call('/api/v1/projects')).to eq(forbidden)
    end

    it 'passes a request with the right secret' do
      expect(call('/api/v1/projects', 'HTTP_X_CLOUDFRONT_SECRET' => 's3cret')).to eq(passed)
    end

    it 'lets the health check through without the secret' do
      expect(call('/up')).to eq(passed)
    end

    it 'does not let a traversal through the health path skip the check' do
      expect(call('/up/../api/v1/admin/projects')).to eq(forbidden)
    end

    it 'rejects every request when the secret is blank' do
      stub_const('ENV', ENV.to_h.merge('CLOUDFRONT_SECRET' => ''))

      expect(call('/api/v1/projects', 'HTTP_X_CLOUDFRONT_SECRET' => '')).to eq(forbidden)
    end
  end
end
