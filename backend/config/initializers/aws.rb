require "aws-sdk-s3"

if ENV["AWS_ACCESS_KEY_ID"].present? && ENV["AWS_SECRET_ACCESS_KEY"].present?
  Aws.config.update(
    region: ENV.fetch("AWS_REGION", "us-east-1"),
    credentials: Aws::Credentials.new(
      ENV.fetch("AWS_ACCESS_KEY_ID"),
      ENV.fetch("AWS_SECRET_ACCESS_KEY")
    )
  )
end
