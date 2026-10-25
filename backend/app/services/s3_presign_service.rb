class S3PresignService
  EXTENSIONS = {
    "image/jpeg" => ".jpg",
    "image/png" => ".png",
    "image/gif" => ".gif",
    "image/webp" => ".webp"
  }.freeze
  EXPIRY = 300 # 5 minutes

  class UnsupportedContentType < StandardError; end

  # The key extension and the signed Content-Type both come from the validated
  # content type, so the client cannot name the object or change its type.
  def self.generate_presigned_url(content_type:)
    ext = EXTENSIONS.fetch(content_type) do
      raise UnsupportedContentType, "Unsupported content type: #{content_type}. Allowed: #{EXTENSIONS.keys.join(', ')}"
    end

    bucket = ENV.fetch("AWS_S3_BUCKET")
    key = "blog-images/#{SecureRandom.uuid}#{ext}"

    signer = Aws::S3::Presigner.new
    presigned_url = signer.presigned_url(
      :put_object,
      bucket: bucket,
      key: key,
      content_type: content_type,
      expires_in: EXPIRY
    )

    public_url = "https://#{ENV.fetch("ASSETS_HOST")}/#{key}"

    { presigned_url: presigned_url, public_url: public_url, key: key }
  end
end
