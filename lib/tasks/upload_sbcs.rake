require 'csv'
require Rails.root.join("lib", "sbc", "sbc_processor")
namespace :sbc do
  #USAGE rake sbc:upload['MASTER 2016 QHP_QDP IVAL & SHOP Plan and Rate Matrix v.9.xlsx','v.2 SBCs 9.22.2015']
  task :upload, [:matrix_path, :dir_path] => :environment do |task, args|
    sbc_processor = SbcProcessor.new(args.matrix_path, args.dir_path)
    sbc_processor.run
  end

  # USAGE rake sbc:export
  # This will export a map of plan and sbc pdfs in S3 to plans-sbcs.csv
  # A CSV with plan.id, plan.hios_id, plan.active_year, plan.sbc_document.identifier, plan.sbc_document.title
  task :export => :environment do
    file_path = "plans-sbcs.csv"
    plans = Plan.all
    csv = CSV.open(file_path, "w") do |csv|
      plans.each do |plan|
        next unless plan.sbc_document
        csv << [plan.id, plan.hios_id, plan.active_year, plan.sbc_document.identifier, plan.sbc_document.title]
      end
    end
    puts "CSV written #{file_path} with schema plan.id, plan.hios_id, plan.active_year, plan.sbc_document.identifier, plan.sbc_document.title"
  end

  # USAGE rake sbc:export
  # Seeds the SBC documents in Plans. SBCs are already uploaded to S3 before this runs.
  # Should run while seeding.
  task :map => :environment do
    file_path = Rails.root.join("db","seedfiles","plans-sbcs.csv").to_s
    counter = 0
    CSV.foreach(file_path) do |row|
      plan = Plan.where(hios_id:row[1]).and(active_year:row[2]).first
      next unless plan
      plan.sbc_document = Document.new({title: row[4], subject: "SBC", format: 'application/pdf', identifier: row[3]})
      plan.sbc_document.save!
      plan.save!
      counter += 1
    end
    puts "Total #{counter} plans updated with sbc_documents"
  end
end