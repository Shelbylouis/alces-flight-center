
# Utility functions only for use in development; if these become generally
# needed then they should be moved elsewhere.
module Development
  module Utils
    class << self
      def upload_document_fixtures_for(cluster)
        s3 = Aws::S3::Resource.new(region: ENV.fetch('AWS_REGION'))
        bucket = s3.bucket(ENV.fetch('AWS_DOCUMENTS_BUCKET'))
        Pathname.glob('fixtures/documents/*').each do |document|
          document_object_path = File.join(cluster.documents_path, document.basename)
          document_object = bucket.object(document_object_path)
          document_object.upload_file(document)
        end
      end
    end
  end
end
