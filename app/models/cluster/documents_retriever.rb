
module Cluster::DocumentsRetriever
  Document = Struct.new(:name, :url)

  class << self
    ACCESS_KEY_ID = ENV.fetch('AWS_ACCESS_KEY_ID')
    SECRET_ACCESS_KEY = ENV.fetch('AWS_SECRET_ACCESS_KEY')
    BUCKET = ENV.fetch('AWS_DOCUMENTS_BUCKET')
    REGION = ENV.fetch('AWS_REGION')

    def retrieve(documents_path)
      objects_under_path(documents_path).map do |object|
        if object.size == 0
          # An empty object ending with `/` is normally handled as a 'folder',
          # which we don't want to display to users.
          nil
        else
          object_bucket_path = Pathname.new(object.key)
          name = object_bucket_path.relative_path_from(
            Pathname.new(documents_path)
          ).to_s

          url = presigned_url_for(object)

          Document.new(name, url)
        end
      end.reject(&:nil?)
    rescue Aws::S3::Errors::ServiceError
      []
    end

    private

    def objects_under_path(path)
      s3 = Aws::S3::Resource.new(
        access_key_id: ACCESS_KEY_ID,
        secret_access_key: SECRET_ACCESS_KEY,
        region: REGION
      )
      response = s3.client.list_objects(
        bucket: BUCKET,
        prefix: path
      )
      response.contents
    end

    def presigned_url_for(object)
      presigner = Aws::S3::Presigner.new
      presigner.presigned_url(
        :get_object,
        bucket: BUCKET,
        key: object.key,
        expires_in: 60.minutes.to_i
      )
    end
  end
end
