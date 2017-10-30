
# Utility functions only for use in development; if these become generally
# needed then they should be moved elsewhere.
module Development
  module Utils
    DOCUMENT_FIXTURES_PATH = Pathname.new('fixtures/documents')

    class << self
      def upload_document_fixtures_for(cluster)
        # Could delete existing files under Cluster path - would ensure only
        # fixture files exist for Cluster, but would be destructive to existing
        # data.
        s3 = Aws::S3::Resource.new(region: ENV.fetch('AWS_REGION'))
        bucket = s3.bucket(ENV.fetch('AWS_DOCUMENTS_BUCKET'))

        Pathname.glob("#{DOCUMENT_FIXTURES_PATH}/**/*").each do |fixture_path|

          document_object_path = File.join(
            cluster.documents_path,
            fixture_path.relative_path_from(DOCUMENT_FIXTURES_PATH).to_s
          )
          # Uploaded directory won't appear as 'folder' unless trailing `/`
          # added.
          document_object_path += '/' if fixture_path.directory?

          document_object = bucket.object(document_object_path)

          if fixture_path.directory?
            # Upload directory as empty object; this is functionally equivalent
            # to what creating 'folder' in AWS interface does.
            document_object.put(body: '')
          else
            document_object.upload_file(fixture_path)
          end
        end
      end
    end
  end
end
