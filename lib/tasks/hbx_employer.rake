require 'csv'
require 'tasks/hbx_employer_import'

namespace :hbx do
  namespace :employers do
    desc "Import new employers from csv files."
    task :add, [:employer_file_name, :ignore_file_name] => [:environment] do |t, args|
      import = HbxEmployerImport.new(args[:employer_file_name], args[:ignore_file_name])
      import.run
    end

    namespace :census do
    end
  end
end
