# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    class EligibilitiesEventLog
      include Mongoid::Document
      include Mongoid::Timestamps
      include ::EventLog
    end
  end
end
