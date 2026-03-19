require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Uploads', type: :request do
  let!(:admin) { create(:admin) }
  let(:headers) { auth_headers(admin) }

  before do
    stub_const('ENV', ENV.to_h.merge(
      'AWS_S3_BUCKET' => 'test-bucket',
      'AWS_REGION' => 'us-east-1'
    ))

    presigner = instance_double(Aws::S3::Presigner)
    allow(Aws::S3::Presigner).to receive(:new).and_return(presigner)
    allow(presigner).to receive(:presigned_url).and_return('https://test-bucket.s3.amazonaws.com/presigned')
  end

  describe 'POST /api/v1/admin/uploads/presign' do
    let(:valid_params) do
      { filename: 'photo.jpg', content_type: 'image/jpeg' }
    end

    it 'returns presigned URL data for valid image type' do
      post '/api/v1/admin/uploads/presign', params: valid_params, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:presigned_url]).to be_present
      expect(json_data[:public_url]).to be_present
      expect(json_data[:key]).to match(%r{\Ablog-images/[a-f0-9-]+\.jpg\z})
    end

    it 'returns correct public URL format' do
      post '/api/v1/admin/uploads/presign', params: valid_params, headers: headers, as: :json

      expect(json_data[:public_url]).to start_with('https://test-bucket.s3.us-east-1.amazonaws.com/blog-images/')
    end

    %w[image/jpeg image/png image/gif image/webp image/svg+xml].each do |type|
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
    end

    it 'returns 400 when filename is missing' do
      post '/api/v1/admin/uploads/presign',
           params: { content_type: 'image/jpeg' },
           headers: headers, as: :json

      expect(response).to have_http_status(:bad_request)
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
