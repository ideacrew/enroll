require 'nokogiri'

module CheckbookServices
  class PlanComparision
    attr_accessor :census_employee
    REMOTE_ACCESS_KEY = "B48E5D58B6A64B3E93A6BF719647E568"
    BASE_URL =  "https://staging.checkbookhealth.org/shop/dc/2016/"
    def initialize(census_employee)
      @census_employee= census_employee
      @url = "https://staging.checkbookhealth.org/shop/dc/api/"
    end

    def generate_url
      begin
      puts construct_body

      @result = HTTParty.post(@url,
              :body => construct_body.to_json,
              :headers => { 'Content-Type' => 'application/json' } )
      @doc=Nokogiri::HTML(@result.parsed_response)
      uri = @doc.xpath("//*[@id='inner_body']/div/article/div[2]/a/@href")
      # byebug
      if uri.present?
        return BASE_URL+uri.first.value
      else
        raise "Unable to generate url"
      end
      rescue Exception => e
        puts "Exception #{e}"
      end
    end


    private 
    def construct_body
    {
      "remote_access_key": REMOTE_ACCESS_KEY,
      "reference_id": "9F03A78ADF324AFDBFBEF8E838770132",
      "employer_effective_date": census_employee.active_benefit_group.plan_year.start_on,
      "employee_coverage_date": census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.first.effective_on,
      "employer": {
        "state": 11, #census_employee.employer_profile.organization.primary_office_location.address.state, #TODO Fix these
        "county": 111 #census_employee.employer_profile.organization.primary_office_location.address.state 
      },
      "family": build_family,
      "contribution": employer_contributions,
      "reference_plan": "21066DC0010014",#census_employee.employer_profile.plan_years.first.benefit_groups.first.reference_plan.hios_id,
      "plans_available": ["41842DC0040047"]#["21066DC0010009","21066DC0010010","21066DC0010011"]
    }
    end

    def employer_contributions
      premium_benefit_contributions = {}
      census_employee.employer_profile.plan_years.first.benefit_groups.first.relationship_benefits.each do |relationship_benefit| 
        # next if relationship_benefit.premium_pct.to_i <= 0 
        premium_benefit_contributions[relationship_benefit.relationship]=relationship_benefit.premium_pct.to_f
      end
      premium_benefit_contributions
    end


    def build_family
      family = [{'dob': census_employee.dob,'relationship': 'self'}]
      census_employee.census_dependents.each do |dependent|
        family << [{'dob': dependent.dob,'relationship': dependent.employee_relationship}]
      end
      family
    end
  end
end