# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ModuleLength
# rubocop:disable Style/Documentation
module BenefitSponsors
  module ClientOrganizationSpecHelpers
    module ME
      def general_organization_properties(site)
        org_id = BSON::ObjectId.new
        legal_name  = "ACME Widgets, Inc."
        dba         = "ACME Co."
        entity_kind = :c_corporation
        fein = Forgery('basic').text(
          :allow_lower => false,
          :allow_upper => false,
          :allow_numeric => true,
          :allow_special => false, :exactly => 9
        )
        ep_props = employer_profile_properties
        org_props = {
          _id: org_id,
          hbx_id: "ALKJVFKLEIJDSLF",
          fein: fein,
          dba: dba,
          entity_kind: entity_kind,
          legal_name: legal_name,
          _type: "BenefitSponsors::Organizations::GeneralOrganization",
          site_id: site.id,
          profiles: [
            ep_props
          ]
        }
        BenefitSponsors::Organizations::Organization.collection.insert_one(org_props)
        org_id
      end

      def employer_profile_properties
        inbox_id = BSON::ObjectId.new
        inbox_access_key = [inbox_id.to_s, SecureRandom.hex(10)].join
        ep_id = BSON::ObjectId.new
        ol_id = BSON::ObjectId.new
        address_id = BSON::ObjectId.new
        phone_id = BSON::ObjectId.new
        o_location_props = {
          _id: ol_id,
          is_primary: true,
          address: {
            _id: address_id,
            kind: "primary",
            address_1: "27 Reo Road",
            address_2: "Apt 1111",
            city: EnrollRegistry[:enroll_app].setting(:contact_center_city).item.to_s,
            state: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.to_s,
            zip: EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item.to_s
          },
          phone: {
            _id: phone_id,
            kind: "work",
            area_code: "617",
            number: "5551212"
          }
        }
        {
          _id: ep_id,
          is_benefit_sponsorship_eligible: true,
          _type: "BenefitSponsors::Organizations::AcaShopMeEmployerProfile",
          contact_method: :paper_and_electronic,
          documents: [],
          inbox: {
            _id: inbox_id,
            access_key: inbox_access_key,
            messages: []
          },
          office_locations: [
            o_location_props
          ]
        }
      end

      def with_aca_shop_employer_profile(site)
        general_organization_properties(site)
        # FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{EnrollRegistry[:enroll_app].setting(:site_key).item}_employer_profile".to_sym, site: site)
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Style/Documentation
