# frozen_string_literal: true

module BenefitSponsors
  # Used to load conversion employer plan year through script
  #
  # @return nil if data imported and put the results in conversion_employer_results file
  # @raise exception if file is not excel or csv or error raised during data import
  class ConversionEmployerPlanYears

    def import_employer(in_file)
      config = YAML.load_file("#{Rails.root}/conversions.yml")
      result_file = File.open(File.join(Rails.root, "conversion_employer_plan_year_results", "RESULT_PLAN_YEARS_#{File.basename(in_file)}.csv"), 'wb')

      importer = ::Importers::ConversionEmployerPlanYearSet.new(in_file, result_file, config["conversions"]["plan_year_date"])

      importer.import!
      result_file.close

      puts "***" * 8 unless Rails.env.test?
      puts "Placed the results under folder conversion_employer_plan_years_results" unless Rails.env.test?
    rescue StandardError => e
      puts e.message
      puts e.backtrace.inspect
    end
  end
end

dir_glob = File.join(Rails.root, "conversion_employer_plan_years", "*.{xlsx,csv}")

Dir.glob(dir_glob).each do |file|
  puts "started processing the file : #{file}"
  conversion_object = BenefitSponsors::ConversionEmployerPlanYears.new
  conversion_object.import_employer(file)
end
