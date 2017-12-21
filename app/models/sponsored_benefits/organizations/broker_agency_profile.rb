module SponsoredBenefits
  module Organizations
    class BrokerAgencyProfile < Profile

      has_many :plan_design_organizations, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization", inverse_of: :broker_agency_profile


      # All PlanDesignOrganizations that belong to this BrokerRole/BrokerAgencyProfile
      def employer_leads
      end

      class << self

        def find(id)
          SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(id).first
        end

        def assign_employer(broker_agency:, employer:, office_locations:)
          org = SponsoredBenefits::Organizations::Organization.find_or_initialize_by(fein: broker_agency.fein)

          org.update_attributes({
            hbx_id: broker_agency.hbx_id,
            legal_name: broker_agency.legal_name,
            dba: broker_agency.dba,
            is_active: broker_agency.is_active,
            office_locations: broker_agency.organization.office_locations
          })

          broker_profile = org.broker_agency_profile = SponsoredBenefits::Organizations::BrokerAgencyProfile.new()

          broker_profile.plan_design_organizations.new().tap do |org|
            org.owner_profile_id = broker_agency._id
            org.customer_profile_id = employer._id
            org.office_locations = office_locations
            org.fein = employer.fein
            org.legal_name = employer.legal_name

            org.build_plan_design_profile(sic_code: employer.sic_code)
            org.save!
          end

          org.save!
        end
      end

    end
  end
end
