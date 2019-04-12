module SponsoredBenefits
  module Accounts
    class GeneralAgencyAccount
        include Mongoid::Document
        include Mongoid::Timestamps
        include AASM

        embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"
        embeds_many :workflow_state_transitions, as: :transitional, class_name: "::WorkflowStateTransition"

        # Begin date of relationship
        field :start_on, type: DateTime
        # End date of relationship
        field :end_on, type: DateTime
        field :updated_by, type: String
        field :general_agency_profile_id, type: BSON::ObjectId
        field :aasm_state, type: Symbol, default: :active
        field :broker_role_id, type: BSON::ObjectId
        field :broker_agency_profile_id, type: BSON::ObjectId

        scope :active, ->{ where(aasm_state: :active) }
        scope :inactive, ->{ where(aasm_state: :inactive) }

        validates_presence_of :start_on, :general_agency_profile_id

        # belongs_to general_agency_profile
        def general_agency_profile=(profile)
          raise ArgumentError.new("expected GeneralAgencyProfile") unless profile.is_a?(GeneralAgencyProfile)
          self.general_agency_profile_id = profile._id
          @general_agency_profile = profile
        end

        def general_agency_profile
          return @general_agency_profile if defined? @general_agency_profile
          @general_agency_profile = ::GeneralAgencyProfile.find(general_agency_profile_id)
        end

        def broker_agency_profile
          ::BrokerAgencyProfile.find(broker_agency_profile_id) || BenefitSponsors::Organizations::Profile.find(broker_agency_profile_id)
        end


        def ga_name
          Rails.cache.fetch("general-agency-name-#{self.general_agency_profile_id}", expires_in: 12.hour) do
            legal_name
          end
        end


        def legal_name
          general_agency_profile.present? ? general_agency_profile.legal_name : ""
        end

        def broker_role
          broker_role_id.present? ? ::BrokerRole.find(broker_role_id) : nil
        end

        def broker_role_name
          broker_role.present? ? broker_role.person.full_name : ""
        end

        def for_broker_agency_account?(ba_account)
          return false unless (broker_role_id == ba_account.writing_agent_id)
          return false unless general_agency_profile.present?
          if !ba_account.end_on.blank?
            return((start_on >= ba_account.start_on) && (start_on <= ba_account.end_on))
          end
          (start_on >= ba_account.start_on)
        end


        aasm do
          state :active, initial: true
          state :inactive

          event :terminate, after: :record_transition do
            transitions from: :active, to: :inactive
          end
        end

        def record_transition(*args)
          workflow_state_transitions << WorkflowStateTransition.new(
            from_state: aasm.from_state,
            to_state: aasm.to_state,
            event: aasm.current_event,
            user_id: SAVEUSER[:current_user_id]
          )
        end

        class << self
          def find(id)
            pdo = SponsoredBenefits::Organizations::PlanDesignOrganization.where(
              :"general_agency_accounts._id" => BSON::ObjectId.from_string(id)
            ).first

            pdo.general_agency_accounts.where(
              :"_id" => BSON::ObjectId.from_string(id)
            ).first if pdo.present?
          end
        end
    end
  end
end
