def import_employer(in_file)
#  begin
    result_file = File.open(File.join(Rails.root, "conversion_employer_plan_year_results", "RESULT_PLAN_YEARS_" + File.basename(in_file) + ".csv"), 'wb')
    importer = Importers::ConversionEmployerPlanYearSet.new(in_file, result_file, Date.new(2015,7,1))
    importer.import!
    result_file.close
#  rescue
#    raise in_file.inspect
#  end
end

dir_glob = File.join(Rails.root, "conversion_employers", "*.{xlsx,csv}")
Dir.glob(dir_glob).each do |file|
  import_employer(file)
end
