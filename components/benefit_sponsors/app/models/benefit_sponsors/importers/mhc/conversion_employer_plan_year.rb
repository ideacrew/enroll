module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerPlanYear < ::Importers::Mhc::ConversionEmployerPlanYear

      attr_accessor :plan_year_end, :mid_year_conversion


      def find_carrier
        BenefitSponsors::Organizations::IssuerProfile.find_by_abbrev(carrier)
      end

      def find_employer
        org = BenefitSponsors::Organizations::Organization.where(:fein => fein).first
        return nil unless org
        org.profiles.first
      end

      def map_employees_to_benefit_groups(employer, benefit_application)
        benefit_package = benefit_application.benefit_packages.first
        employer.census_employees.each do |ce|
          next unless ce.valid?
          begin
            ce.add_benefit_group_assignment(benefit_package)
            ce.save!
          rescue Exception => e
            puts "Issue adding benefit group to employee:"
            puts "\n#{employer.fein} - #{employer.legal_name} - #{ce.full_name}\n#{e.inspect}\n- #{e.backtrace.join("\n")}"
          end
        end
      end
    end
  end
end