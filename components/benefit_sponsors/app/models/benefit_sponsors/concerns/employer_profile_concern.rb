require 'active_support/concern'

module BenefitSponsors
  module Concerns
    module EmployerProfileConcern
      extend ActiveSupport::Concern
      include StateMachines::EmployerProfileStateMachine

      included do
        ENTITY_KINDS ||= [
          :tax_exempt_organization,
          :c_corporation,
          :s_corporation,
          :partnership,
          :limited_liability_corporation,
          :limited_liability_partnership,
          :household_employer,
          :governmental_employer,
          :foreign_embassy_or_consulate
        ]

        ACTIVE_STATES   ||= ["applicant", "registered", "eligible", "binder_paid", "enrolled"]
        INACTIVE_STATES ||= ["suspended", "ineligible"]

        PROFILE_SOURCE_KINDS  ||= ["self_serve", "conversion"]

        INVOICE_VIEW_INITIAL  ||= %w(published enrolling enrolled active suspended)
        INVOICE_VIEW_RENEWING ||= %w(renewing_published renewing_enrolling renewing_enrolled renewing_draft)

        ENROLLED_STATE ||= %w(enrolled suspended)

        CONTACT_METHODS ||= ["Only Electronic communications", "Paper and Electronic communications"]

        # Workflow attributes
        field :aasm_state, type: String, default: "applicant"

        field :profile_source, type: String, default: "self_serve"
        field :entity_kind, type: Symbol
        field :registered_on, type: Date, default: ->{ TimeKeeper.date_of_record }
        field :xml_transmitted_timestamp, type: DateTime
        field :contact_method, type: String, default: "Only Electronic communications"


        validates :entity_kind,
          inclusion: { in: ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
          allow_blank: false

        validates :profile_source,
          inclusion: { in: PROFILE_SOURCE_KINDS },
          allow_blank: false
        scope :active,      ->{ any_in(aasm_state: ACTIVE_STATES) }
        scope :inactive,    ->{ any_in(aasm_state: INACTIVE_STATES) }

      end

      def parent
        self.organization
      end

      def is_conversion?
        self.profile_source.to_s == "conversion"
      end

      def entity_kinds
        ENTITY_KINDS
      end

      def contact_methods
        CONTACT_METHODS
      end

      def policy_class
        "BenefitSponsors::EmployerProfilePolicy"
      end
    end
  end
end
