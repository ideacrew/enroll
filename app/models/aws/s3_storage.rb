module Aws
  class S3Storage

    def initialize
      setup
    end

    # If success, return URI which has the s3 bucket key
    # else return nil
    def save(file_path, bucket_name, key=SecureRandom.uuid)
      uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:<#{bucket_name}>##{key}"
      begin
        object = get_object(bucket_name, key)
        if object.upload_file(file_path)
          uri
        else
          nil
        end
      rescue Exception => e
        nil
      end
    end

    # If success, return URI which has the s3 bucket key
    # else return nil
    def self.save(file_path, bucket_name, key=SecureRandom.uuid)
      Aws::S3Storage.new.save(file_path, bucket_name, key)
    end

    def self.find

    end

    private
    def get_object(bucket_name, key)
      @resource.bucket(bucket_name).object(key)
    end

    def setup
      client=Aws::S3::Client.new
      @resource=Aws::S3::Resource.new(client: client)
    end
  end
end