module BenefitSponsors
  module RegistrationHelper
    include HtmlScrubberUtil

    def is_broker_profile?(profile_type)
      profile_type == "broker_agency"
    end

    def is_sponsor_profile?(profile_type)
      profile_type == "benefit_sponsor"
    end

    def is_general_agency_profile?(profile_type)
      profile_type == "general_agency"
    end
  end
end
