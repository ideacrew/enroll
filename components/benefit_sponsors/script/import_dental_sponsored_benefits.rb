# Used to Add Denetal sponsored benefits to existing convesion employers
#
# @return nil if data imported and put the results in conversion_employer_results file
# @raise exception if file is not excel or csv or error raised during data import
module BenefitSponsors
  class ImportDentalSponsoredBenefits

    def import_employer(in_file)
      begin
        config = YAML.load_file("#{Rails.root}/conversions.yml")
        result_file = File.open(File.join(Rails.root, "conversion_employer_plan_year_results", "RESULT_DENTAL_SPONSORED_BENEFITS_" + File.basename(in_file) + ".csv"), 'wb')

        if BenefitSponsors::Site.by_site_key(:cca).present?
          importer = BenefitSponsors::Importers::Mhc::ConversionEmployerDentalImport.new(in_file, result_file, config)
        end

        importer.import!
        result_file.close

        puts "***" * 8 unless Rails.env.test?
        puts "Placed the results under folder conversion_employer_plan_years_results" unless Rails.env.test?

      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      end
    end
  end
end

dir_glob = File.join(Rails.root, "conversion_employer_plan_years", "*.{xlsx,csv}")

Dir.glob(dir_glob).sort.each do |file|
  puts "started processing the file : #{file}"
  conversion_object = BenefitSponsors::ImportDentalSponsoredBenefits.new
  conversion_object.import_employer(file)
end
