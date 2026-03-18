module Api
  module V1
    module Admin
      class UploadsController < BaseController
        def presign
          result = S3PresignService.generate_presigned_url(
            filename: params.require(:filename),
            content_type: params.require(:content_type)
          )
          render_success(result)
        rescue S3PresignService::UnsupportedContentType => e
          render_error(e.message, status: :unprocessable_content)
        end
      end
    end
  end
end
