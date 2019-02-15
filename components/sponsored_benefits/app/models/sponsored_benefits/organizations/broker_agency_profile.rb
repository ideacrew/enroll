module SponsoredBenefits
  module Organizations
    class BrokerAgencyProfile < Profile

      has_many :plan_design_organizations, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization", inverse_of: :broker_agency_profile
      accepts_nested_attributes_for :plan_design_organizations, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

      # All PlanDesignOrganizations that belong to this BrokerRole/BrokerAgencyProfile
      def employer_leads
      end

      class << self

        def find(id)
          SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(id).first
        end

        def cca_profile_office_locations(profile)
          profile.office_locations if Settings.aca.state_abbreviation == "MA" # Bring in aca helper
        end

        def dc_profile_office_locations(profile)
          profile.organization.office_locations if Settings.aca.state_abbreviation == "DC" # Bring in aca helper
        end

        def office_locations(profile)
          cca_profile_office_locations(profile) || dc_profile_office_locations(profile)
        end

        def find_or_initialize_broker_profile(profile)
          organization = SponsoredBenefits::Organizations::Organization.find_or_initialize_by(fein: profile.fein)
          unless organization.persisted?
            organization.assign_attributes({
              hbx_id: profile.hbx_id,
              legal_name: profile.legal_name,
              dba: profile.dba,
              office_locations: office_locations(profile).map(&:attributes),
              broker_agency_profile: self.new
            })
          end
          organization
        end

        def init_plan_design_organization(broker_agency, employer)
          broker_profile = find_or_initialize_broker_profile(broker_agency).broker_agency_profile
          plan_design_organization = broker_profile.plan_design_organizations.new({
            owner_profile_id: broker_agency._id,
            sponsor_profile_id: employer._id,
            office_locations: office_locations(employer).map(&:attributes),
            fein: employer.fein,
            legal_name: employer.legal_name,
            has_active_broker_relationship: true
          })

          plan_design_organization.assign_attributes({
            sic_code: employer.sic_code
          }) if Settings.aca.state_abbreviation == "MA" # Bring in aca helper

          broker_profile.save!
        end

        def assign_employer(broker_agency:, employer:)
          plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner_and_sponsor(broker_agency.id, employer.id)
          if plan_design_organization
            plan_design_organization.update_attributes!({
              has_active_broker_relationship: true,
              office_locations: office_locations(employer).map(&:attributes),
            })
          else
            init_plan_design_organization(broker_agency, employer)
          end
        end

        def unassign_broker(broker_agency:, employer:)
          return if broker_agency.nil?
          plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner_and_sponsor(broker_agency.id, employer.id)
          return unless plan_design_organization.present?
          plan_design_organization.has_active_broker_relationship = false
          plan_design_organization.sic_code ||= employer.sic_code
          plan_design_organization.save!
          plan_design_organization.expire_proposals
        end
      end

    end
  end
end
