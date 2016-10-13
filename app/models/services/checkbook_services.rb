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
      # # Checkbook url is still not working so commented below lines
      @result = HTTParty.post(@url,
              :body => construct_body.to_json,
              :headers => { 'Content-Type' => 'application/json' } )
      @doc=Nokogiri::HTML(@result.parsed_response)
      uri = @doc.xpath("//*[@id='inner_body']/div/article/div[2]/a/@href")
      byebug
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
      "employer_effective_date": census_employee.benefit_group_assignments.first.try(:start_on),
      "employee_coverage_date": "2016-11-01", ##TODO 
      "employer": {
        "state": census_employee.employer_profile.organization.primary_office_location.address.state, #TODO Fix these
        "county": census_employee.employer_profile.organization.primary_office_location.address.state 
      },
      "family":[build_family

               ],
      "contribution": {
       "employee":100,
       "spouse":50,
       "domestic_partner":50,
       "child":50
      },
      "reference_plan":  "21066DC0010014",   #census_employee.employer_profile.plan_years.first.benefit_groups.first.reference_plan.hios_id,
      "plans_available": ["41842DC0040047"]#["21066DC0010009","21066DC0010010","21066DC0010011"]
    }
    end

    # def construct_body
    #  {
    #             "remote_access_key": "B48E5D58B6A64B3E93A6BF719647E568",
    #             "reference_id": "9F03A78ADF324AFDBFBEF8E838770132",
    #             "employer_effective_date": "2016-10-01",
    #             "employee_coverage_date": "2016-11-01",
    #             "employer": {
    #                             "state": 11,
    #                             "county": 111
    #             },
    #             "family": [
    #                             {
    #                                             "dob": "1980-04-17",
    #                                             "relationship": "self"
    #                             },
    #                             {
    #                                             "dob": "1990-08-22",
    #                                             "relationship": "spouse"
    #                             },
    #                             {
    #                                             "dob": "2011-02-24",
    #                                             "relationship": "child"
    #                             },
    #                             {
    #                                             "dob": "2012-07-31",
    #                                             "relationship": "child"
    #                             }
    #             ],
    #             "contribution": {
    #                             "employee": 50,
    #                             "spouse": 50,
    #                             "domestic_partner": 50,
    #                             "child": 50
    #             },
    #             "reference_plan": "573e1753c5231b2f6f00eb9c",
    #             "plans_available": [
    #                             "41842DC0040047"
                           
    #             ]
    #   }
    # end


    def build_family
      family = [{'dob': census_employee.dob,'relationship': 'self'}]
      census_employee.census_dependents.each do |dependent|
        family << [{'dob': dependent.dob,'relationship': dependent.employee_relationship}]
      end
      family
    end
  end
end