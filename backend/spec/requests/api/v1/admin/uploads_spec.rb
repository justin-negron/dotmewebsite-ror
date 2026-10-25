require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Uploads', type: :request do
  let!(:admin) { create(:admin) }
  let(:headers) { auth_headers(admin) }
  let(:presigner) { instance_double(Aws::S3::Presigner) }

  before do
    stub_const('ENV', ENV.to_h.merge(
      'AWS_S3_BUCKET' => 'test-bucket',
      'AWS_REGION' => 'us-east-1',
      'ASSETS_HOST' => 'assets.example.com'
    ))

    allow(Aws::S3::Presigner).to receive(:new).and_return(presigner)
    allow(presigner).to receive(:presigned_url).and_return('https://test-bucket.s3.amazonaws.com/presigned')
  end

  describe 'POST /api/v1/admin/uploads/presign' do
    let(:valid_params) do
      { filename: 'photo.jpg', content_type: 'image/jpeg' }
    end

    it 'returns the presigned PUT URL, a jpg key and its CDN URL' do
      post '/api/v1/admin/uploads/presign', params: valid_params, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:presigned_url]).to eq('https://test-bucket.s3.amazonaws.com/presigned')
      expect(json_data[:key]).to match(%r{\Ablog-images/\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\.jpg\z})
      expect(json_data[:public_url]).to eq("https://assets.example.com/#{json_data[:key]}")
    end

    it 'binds the presigned PUT to the bucket, key, content type and a 5 minute expiry' do
      post '/api/v1/admin/uploads/presign',
           params: { filename: 'photo.png', content_type: 'image/png' },
           headers: headers, as: :json

      expect(presigner).to have_received(:presigned_url).with(
        :put_object, bucket: 'test-bucket', key: json_data[:key], content_type: 'image/png', expires_in: 300
      )
    end

    it 'derives the key extension from the content type, not the filename' do
      post '/api/v1/admin/uploads/presign',
           params: { filename: 'x.html', content_type: 'image/png' },
           headers: headers, as: :json

      expect(json_data[:key]).to end_with('.png')
    end

    it 'uses the webp extension for image/webp' do
      post '/api/v1/admin/uploads/presign',
           params: { filename: 'photo', content_type: 'image/webp' },
           headers: headers, as: :json

      expect(json_data[:key]).to match(%r{\Ablog-images/\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\.webp\z})
    end

    it 'returns a public URL that BlogPost accepts as cover_image_url' do
      post '/api/v1/admin/uploads/presign',
           params: { filename: 'My Photo (1).JPG', content_type: 'image/jpeg' },
           headers: headers, as: :json

      expect(build(:blog_post, cover_image_url: json_data[:public_url])).to be_valid
    end

    %w[image/jpeg image/png image/gif image/webp].each do |type|
      it "accepts #{type}" do
        post '/api/v1/admin/uploads/presign',
             params: { filename: "file.#{type.split('/').last}", content_type: type },
             headers: headers, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    it 'returns 422 for unsupported content type' do
      post '/api/v1/admin/uploads/presign',
           params: { filename: 'document.pdf', content_type: 'application/pdf' },
           headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:message]).to start_with('Unsupported content type: application/pdf')
    end

    it 'refuses SVG' do
      post '/api/v1/admin/uploads/presign',
           params: { filename: 'logo.svg', content_type: 'image/svg+xml' },
           headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:message]).to start_with('Unsupported content type: image/svg+xml')
    end

    it 'returns 400 when content_type is missing' do
      post '/api/v1/admin/uploads/presign',
           params: { filename: 'photo.jpg' },
           headers: headers, as: :json

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 401 without auth headers' do
      post '/api/v1/admin/uploads/presign', params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'generates unique keys for each request' do
      post '/api/v1/admin/uploads/presign', params: valid_params, headers: headers, as: :json
      key1 = json_data[:key]

      post '/api/v1/admin/uploads/presign', params: valid_params, headers: headers, as: :json
      key2 = json_data[:key]

      expect(key1).not_to eq(key2)
    end
  end
end
