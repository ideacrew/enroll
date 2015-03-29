require 'csv'
require 'tasks/hbx/employer_import'
require 'tasks/hbx/census_import'

namespace :hbx do
  namespace :employers do
    desc "Import new employers from csv files."
    task :add, [:employer_file_name, :ignore_file_name] => [:environment] do |t, args|
      import = Hbx::EmployerImport.new(args[:employer_file_name], args[:ignore_file_name])
      import.run
    end

    namespace :census do
      desc "Import new employer census from csv file."
      task :add, [:file_name] => [:environment] do |t, args|
        import = Hbx::CensusImport.new(args[:file_name])
        import.run
      end
    end
  end
end
