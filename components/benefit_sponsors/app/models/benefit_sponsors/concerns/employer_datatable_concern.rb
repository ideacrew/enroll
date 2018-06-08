require 'active_support/concern'

module BenefitSponsors
  module Concerns
    module EmployerDatatableConcern
      extend ActiveSupport::Concern

      included do


        scope :datatable_search,        ->(query) { where(:"hbx_id" => ::Regexp.compile(::Regexp.escape(query), true))}

        scope :created_in_the_past,    ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                   :"created_at".lte => compare_date )
                                                                                 }

         scope :benefit_sponsorship_applicant, -> () {
           where(:"aasm_state" => :applicant)
         }

        scope :benefit_application_enrolling, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::ENROLLING_STATES)
        }

        scope :benefit_application_enrolled, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::APPROVED_STATES)
        }

        scope :benefit_application_published, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES)
        }

        scope :benefit_application_draft, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::APPLICATION_DRAFT_STATES)
        }

        scope :benefit_application_renewing, -> () {
          where(:"benefit_applications.predecessor_application" => {:$exists => true},
                :"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::APPLICATION_DRAFT_STATES)
        }

      end

    end
  end
end
