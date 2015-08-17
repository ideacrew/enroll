module Aws
  class S3Storage

    def initialize
      client=Aws::S3::Client.new
      @resource= Aws::S3::Resource.new(client: client)
    end

    def save(file, bucket_name, key=SecureRandom.uuid)
      begin
        object = @resource.bucket(bucket_name).object(key)
        object.upload_file(file)
        SecureRandom.uuid
      rescue Exception => e
        nil
      end
    end

    def self.save(file, bucket_name, key=SecureRandom.uuid)
      client=Aws::S3::Client.new
      @resource= Aws::S3::Resource.new(client: client)
      begin
        object = @resource.bucket(bucket_name).object(key)
        object.upload_file(file)
        key
      rescue Exception => e
        false
      end
    end

    def find

    end

  end
end