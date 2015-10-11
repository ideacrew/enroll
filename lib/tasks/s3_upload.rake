require 'csv'
require Rails.root.join("app", "models", "aws", "s3_storage")

namespace :s3 do
  # USAGE rake s3:upload['list-of-files.csv']
  # csv schema = bucket-name,file-path,key
  # key is optional in csv
  task :upload, [:file_path] => :environment do |task, args|
    CSV.foreach(args.file_path) do |row|
      if row[2].present?
        uri = Aws::S3Storage.save(row[1], row[0], row[2])
      else
        uri = Aws::S3Storage.save(row[1], row[0])
      end
      if uri
        puts "SUCCESS #{row[1]},#{uri}"
      else
        puts "FAILURE bucket #{row[0]} file #{row[1]}"
      end
    end
  end
end