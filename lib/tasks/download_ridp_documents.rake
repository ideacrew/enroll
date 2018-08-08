require 'aws-sdk'

# RAILS_ENV=production bundle exec rake reports:download_ridp_documents hbx_id="123456"
namespace :reports do
  desc 'Downloading Identity and applications documents of a person'
  task :download_ridp_documents => :environment do
    get_person.each do |person|
      begin
        @s3 = Aws::S3::Resource.new(region: 'us-east-1',
                                    access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                    secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
                                    )

        person.consumer_role.ridp_documents.each do |document|
          file_path = "ridp_documents/#{document.ridp_verification_type}_#{document.created_at.strftime("%Y-%m-%d")}"
          dirname = File.dirname(file_path)
          unless File.directory?(dirname)
            FileUtils.mkdir_p(dirname)
          end
          @s3.bucket("#{get_bucket_name('id-verification')}").object("#{get_access_key(document)}").get(response_target: file_path)
        end
      rescue => e
        puts "Invalid Person with HBX_ID: #{person.hbx_id}"
      end
    end
  end

  def get_person
    Person.where(hbx_id: ENV['hbx_id'])
  end

  def get_bucket_name(bucket_name)
    aws_env = ENV['AWS_ENV'] || "local"
    "dchbx-enroll-#{bucket_name}-#{aws_env}"
  end

  def get_access_key(document)
    document.identifier.split('#').last
  end

end
