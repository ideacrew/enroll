require 'active_support/concern'

module BenefitSponsors
  module Concerns
    module EmployerDatatableConcern
      extend ActiveSupport::Concern

      included do
        scope :created_in_the_past,    ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                   :"created_at".lte => compare_date )
                                                                                   }
        scope :benefit_application_enrolling, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLING_STATES)
        }

        scope :benefit_application_published, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES)
        }

      end

    end
  end
end
