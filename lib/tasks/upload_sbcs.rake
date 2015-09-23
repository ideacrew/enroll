require Rails.root.join("lib", "sbc", "sbc_processor")
namespace :sbc do
  #USAGE rake sbc:upload['MASTER 2016 QHP_QDP IVAL & SHOP Plan and Rate Matrix v.9.xlsx','v.2 SBCs 9.22.2015']
  task :upload, [:matrix_path, :dir_path] => :environment do |task, args|
    sbc_processor = SbcProcessor.new(args.matrix_path, args.dir_path)
    sbc_processor.run
  end
end