module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerCreate < ConversionEmployer

      def initialize(opts = {})
        super(opts)
      end

      def save
        if valid?
          organization = BenefitSponsors::Organizations::Organization.where(fein: fein).first
          puts "loading conversion employer with legalname --- #{legal_name}" unless Rails.env.test?

          if organization
            #needs helper here
            organization.create_employer_profile(employer_profile_prams)
          else
            new_organization = BenefitSponsors::Organizations::Organization.new(form_organizational_params)
            employer_profile = BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(employer_profile_prams.merge(:organization => new_organization))
            binding.pry

            new_organization.profiles << employer_profile

            benefit_sponsorship = employer_profile.add_benefit_sponsorship
            benefit_sponsorship.update_attributes!(registered_on: registred_on, origin_kind: :conversion)

            set_attestation_to_true(benefit_sponsorship)

            save_result = new_organization.save!

            if save_result
              broker_agency_profile = BenefitSponsors::Organizations::Organization.broker_agency_profiles.where(:corporate_npn => corporate_npn).first
              new_organization.profiles << broker_agency_profile if broker_agency_profile
              map_poc(employer_profile)
            end

            propagate_errors(new_organization.employer_profile)

            return save_result

          end
        end
      end

      def set_attestation_to_true(benefit_sponsorship)
        attestation = benefit_sponsorship.build_employer_attestation
        attestation.submit
        attestation.approve
        attestation.save
      end

      def map_site
        BenefitSponsors::Site.by_site_key(:cca).first if BenefitSponsors::Site.by_site_key(:cca).present?
      end

      def create_broker_agency_profile
        broker_agency_profile = BenefitSponsors::Organizations::Organization.broker_agency_profiles.where(:corporate_npn => corporate_npn).first

      end

      def employer_profile_prams
        {
            :sic_code => sic_code,
            :is_benefit_sponsorship_eligible => true,
            :office_locations => map_office_locations
        }
      end

      def form_organizational_params
        {
            :legal_name => legal_name,
            :dba => dba,
            :fein => fein,
            :entity_kind => fetch_entity_kind,
            :site => map_site
        }
      end

    end
  end
end
