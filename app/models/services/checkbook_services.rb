require 'nokogiri'

module Services
  module CheckbookServices
    class PlanComparision

      attr_accessor :hbx_enrollment,:is_congress

      BASE_URL =  Settings.checkbook_services.base_url
      CONGRESS_URL = Settings.checkbook_services.congress_url

      def initialize(hbx_enrollment, is_congress=false)
        @hbx_enrollment = hbx_enrollment
        @census_employee = @hbx_enrollment.employee_role.census_employee
        @is_congress = is_congress
        is_congress ? @url = CONGRESS_URL : @url = BASE_URL+"/shop/dc/api/"
      end

      def generate_url
        return nil if slug!
        return @url if is_congress
        begin
          puts construct_body.to_json
          @result = HTTParty.post(@url,
                :body => construct_body.to_json,
                :headers => { 'Content-Type' => 'application/json' } )
          uri = @result.parsed_response["URL"]
          if uri.present?
            return uri
          else
            raise "Unable to generate url"
          end
        rescue Exception => e
          Rails.logger.error { "Unable to generate url for #{@census_employee.full_name} due to #{e.backtrace}" }
        end
      end

      private
      def slug!
        Rails.env.test?
      end

      def construct_body
      {
        "remote_access_key": Settings.checkbook_services.remote_access_key,
        "reference_id": Settings.checkbook_services.reference_id,
        "employer_effective_date": @census_employee.active_benefit_group.plan_year.start_on.strftime("%Y-%d-%m"),
        "employee_coverage_date": @hbx_enrollment.effective_on.strftime("%Y-%d-%m"),
        "employer": {
          "state": 11,
          "county": 001
        },
        "family": build_family,
        "contribution": employer_contributions,
        "reference_plan": reference_plan.hios_id,
        "filterOption": filter_option,
        "filterValue": reference_plan.carrier_profile.legal_name
      }
      end


      def filter_option
        case @hbx_enrollment.benefit_group.plan_option_kind
        when "single_plan"
          "Plan"
        when "single_carrier"
          "Carrier"
        when "metal_level"
          "Metal"
        end
      end

      def employer_contributions
        premium_benefit_contributions = {}
        @hbx_enrollment.benefit_group.relationship_benefits.each do |relationship_benefit|
          next if ["child_26_and_over","nephew_or_niece","grandchild","child_26_and_over_with_disability"].include? relationship_benefit.relationship
          relationship=  relationship_benefit.relationship == "child_under_26" ? "child" : relationship_benefit.relationship
          premium_benefit_contributions[relationship] = relationship_benefit.premium_pct.to_i
        end
        premium_benefit_contributions
      end

      def reference_plan
        @hbx_enrollment.benefit_group.reference_plan
      end

      def build_family
        family = [{'dob': @census_employee.dob.strftime("%Y-%d-%m") ,'relationship': 'self'}]
        @census_employee.census_dependents.each do |dependent|
          next if dependent == "nephew_or_niece"
          family << {'dob': dependent.dob.strftime("%Y-%d-%m") ,'relationship': dependent.employee_relationship}
        end
        family
      end
    end
  end
end
