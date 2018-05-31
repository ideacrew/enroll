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

      def map_employees_to_benefit_groups(benefit_sponsorship, benefit_application)
        benefit_package = benefit_application.benefit_packages.first
        # adding to all employees here there is a case employees already added exist in system and terminated
        benefit_sponsorship.census_employees.each do |ce|
          next unless ce.valid?
          begin
            ce.add_benefit_group_assignment(benefit_package)
            ce.save!
          rescue Exception => e
            puts "Issue adding benefit group to employee:"
            puts "\n#{benefit_sponsorship.organization.fein} - #{benefit_sponsorship.organization.legal_name} - #{ce.full_name}\n#{e.inspect}\n- #{e.backtrace.join("\n")}"
          end
        end
      end
    end
  end
end