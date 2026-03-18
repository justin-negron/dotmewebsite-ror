class S3PresignService
  ALLOWED_TYPES = %w[image/jpeg image/png image/gif image/webp image/svg+xml].freeze
  EXPIRY = 300 # 5 minutes

  class UnsupportedContentType < StandardError; end

  def self.generate_presigned_url(filename:, content_type:)
    unless ALLOWED_TYPES.include?(content_type)
      raise UnsupportedContentType, "Unsupported content type: #{content_type}. Allowed: #{ALLOWED_TYPES.join(', ')}"
    end

    bucket = ENV.fetch("AWS_S3_BUCKET")
    region = ENV.fetch("AWS_REGION", "us-east-1")
    ext = File.extname(filename).presence || mime_to_ext(content_type)
    key = "blog-images/#{SecureRandom.uuid}#{ext}"

    signer = Aws::S3::Presigner.new
    presigned_url = signer.presigned_url(
      :put_object,
      bucket: bucket,
      key: key,
      content_type: content_type,
      expires_in: EXPIRY
    )

    public_url = "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"

    { presigned_url: presigned_url, public_url: public_url, key: key }
  end

  def self.mime_to_ext(content_type)
    {
      "image/jpeg" => ".jpg",
      "image/png" => ".png",
      "image/gif" => ".gif",
      "image/webp" => ".webp",
      "image/svg+xml" => ".svg"
    }.fetch(content_type, ".jpg")
  end
end
