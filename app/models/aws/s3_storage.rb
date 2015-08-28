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

    # The uri has information about the bucket name and key e.g. "urn:openhbx:terms:v1:file_storage:s3:bucket:<#{bucket_name}>##{key}"
    # The returned object can be streamed by controller e.g. send_data Aws::S3Storage.find(uri), :stream => true, :buffer_size => ‘4096’
    def find(uri)
      begin
        bucket_and_key = uri.split(':').last
        bucket_name, key = bucket_and_key.split('#')
        object = get_object(bucket_name, key)
        read_object(object)
      rescue Exception => e
        nil
      end
    end

    # The param uri is present in Document model. Document.identifier
    # The uri has information about the bucket name and key e.g. "urn:openhbx:terms:v1:file_storage:s3:bucket:<#{bucket_name}>##{key}"
    # The returned object can be streamed by controller e.g. send_data Aws::S3Storage.find(uri), :stream => true, :buffer_size => ‘4096’
    def self.find(uri)
      Aws::S3Storage.new.find(uri)
    end

    private
    def read_object(object)
      object.get.body.read
    end

    def get_object(bucket_name, key)
      @resource.bucket(bucket_name).object(key)
    end

    def setup
      client=Aws::S3::Client.new
      @resource=Aws::S3::Resource.new(client: client)
    end
  end
end