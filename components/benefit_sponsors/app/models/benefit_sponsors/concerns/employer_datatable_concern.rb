require 'active_support/concern'

module BenefitSponsors
  module Concerns
    module EmployerDatatableConcern
      extend ActiveSupport::Concern

      included do

        scope :datatable_search, ->(query) {
          orgs =  BenefitSponsors::Organizations::Organization.where({"$or" => ([{"legal_name" => ::Regexp.compile(::Regexp.escape(query), true)}, {"fein" => ::Regexp.compile(::Regexp.escape(query), true)}, {"hbx_id" => ::Regexp.compile(::Regexp.escape(query), true)}])})
          self.where(:"organization".in => orgs.collect{|org| org.id.to_s})
        }

        scope :datatable_search_for_source_kind, ->(source_kinds) {where(:"source_kind" => source_kinds) }

        scope :created_in_the_past,    ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                   :"created_at".lte => compare_date )
                                                                                 }

        scope :attestations_by_kind, ->(attestation_kind) {
          orgs =  BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles.employer_attestation.aasm_state" => attestation_kind)
          self.where(:"organization".in => orgs.collect{|org| org.id})}

        scope :employer_attestations, -> {
          orgs =  BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles.employer_attestation.aasm_state".in => EmployerAttestation::ATTESTATION_KINDS)
          self.where(:"organization".in => orgs.collect{|org| org.id.to_s}) }

        scope :benefit_sponsorship_applicant, lambda {
          where({"$or":
            [
              {:aasm_state => :applicant, :"benefit_applications.aasm_state".in => [:draft, :expired, :terminated, :canceled, :retroactive_canceled, :enrollment_ineligible, :approved, :pending],
               :"benefit_applications.predecessor_id" => {:$exists => false}},
              {:benefit_applications => {:$exists => false}}
            ]
          })
        }

        scope :benefit_application_enrolling, -> () {
          where(:"benefit_applications.aasm_state".in => [:draft, :enrollment_open, :enrollment_extended, :enrollment_closed, :enrollment_eligible, :binder_paid])
        }

        scope :benefit_application_enrolling_initial, -> () {
          where(:"benefit_applications.aasm_state".in => [:draft, :enrollment_open, :enrollment_extended, :enrollment_closed, :enrollment_eligible, :binder_paid], :"benefit_applications.predecessor_id" => {:$exists => false})
        }

        scope :benefit_application_enrolling_renewing, -> () {
          where(:"benefit_applications.aasm_state".in => [:draft, :enrollment_open, :enrollment_extended, :enrollment_closed, :enrollment_eligible], :"benefit_applications.predecessor_id" => {:$exists => true})
        }

        scope :benefit_application_enrolling_initial_oe, -> () {
          where(:"benefit_applications.aasm_state".in => [:enrollment_open, :enrollment_extended], :"benefit_applications.predecessor_id" => {:$exists => false})
        }

        scope :benefit_application_enrolling_renewing_oe, -> () {
          where(:"benefit_applications.aasm_state".in => [:enrollment_open, :enrollment_extended], :"benefit_applications.predecessor_id" => {:$exists => true})
        }

        scope :benefit_application_initial_binder_paid, -> () {
          where(:benefit_applications => {:$elemMatch => {:aasm_state => :binder_paid, :predecessor_id => {:$exists => false}}})
        }

        scope :benefit_application_initial_binder_pending, -> () {
          where(:"aasm_state" => :binder_reversed, :"benefit_applications.predecessor_id" => {:$exists => false})
        }

        scope :benefit_application_pending, -> () {
          where(:"benefit_applications.aasm_state".in => [:pending], :"benefit_applications.predecessor_id" => {:$exists => false})
        }

        scope :benefit_application_renewal_pending, -> () {
          where(:"benefit_applications.aasm_state".in => [:pending],:"benefit_applications.predecessor_id" => {:$exists => true})
        }

        scope :benefit_application_imported, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::IMPORTED_STATES)
        }

        scope :benefit_application_enrolled, -> () {
          where(:"benefit_applications.aasm_state".in => [:enrollment_closed, :enrollment_eligible, :active])
        }

        scope :benefit_application_published, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::PUBLISHED_STATES)
        }

        scope :benefit_application_suspended, -> () {
          where(:"benefit_applications.aasm_state".in => [:suspended])
        }

        scope :benefit_application_draft, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::APPLICATION_DRAFT_STATES)
        }

        scope :benefit_application_draft, -> () {
          where(:"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::APPLICATION_DRAFT_STATES)
        }

        scope :effective_date_begin_on, -> (compare_date) {
          where(:"benefit_applications.effective_period.min" => compare_date )
         }

        scope :benefit_application_renewing, -> () {
          where(:"benefit_applications.predecessor_id" => {:$exists => true},
                :"benefit_applications.aasm_state".in => BenefitSponsors::BenefitApplications::BenefitApplication::APPLICATION_DRAFT_STATES)
        }

      end
    end
  end
end
