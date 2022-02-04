# frozen_string_literal: true

# Used to load conversion employee enrollments through script
#
# @return nil if data imported and put the results in conversion_employee_policy_results file
# @raise exception if file is not excel or csv or error raised during data import
module BenefitSponsors
  # here's a comment
  class ConversionEmployeePolicies

    def import_employee(in_file)
      config = YAML.load_file("#{Rails.root}/conversions.yml")
      result_file = File.open(File.join(Rails.root, "conversion_employee_policy_results", "RESULT_#{File.basename(in_file)}.csv"), 'wb')

      importer = if EnrollRegistry[:enroll_app].setting(:site_key).item == :cca
                   BenefitSponsors::Importers::Mhc::ConversionEmployeePolicySet.new(in_file, result_file, config)
                 else
                   Importers::ConversionEmployeePolicySet.new(in_file, result_file, config["conversions"]["employee_policies_date"], config["conversions"]["employee_policy_year"])
                 end
      importer.import!
      result_file.close

      puts "***" * 10 unless Rails.env.test?
      puts "Placed the results under folder conversion_employee_policy_results" unless Rails.env.test?
    end
  end
end

dir_glob = File.join(Rails.root, "conversion_employees", "*.{xlsx,csv}")

Dir.glob(dir_glob).sort.each do |file|
  puts "started processing the file : #{file}"
  conversion_object = BenefitSponsors::ConversionEmployeePolicies.new
  conversion_object.import_employee(file)
end
