# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module Employers
      #This operation will initialize a new employer profile form
      class New
        include Dry::Monads[:result, :do, :try]

        def call(params)
          validated_params = yield validate(params)
          @person = yield find_person(validated_params[:person_id]) if validated_params[:person_id].present?
          @profile = yield find_profile(validated_params[:profile_id]) if validated_params[:profile_id].present?

          employer = yield build_employer(validated_params[:profile_type])
          Success(employer)
        end

        private

        def validate(params)
          if params[:profile_type].blank?
            Failure({:message => ['Missing profile type']})
          elsif !%w[benefit_sponsor].include?(params[:profile_type])
            Failure({:message => ['Invalid profile type']})
          else
            Success(params)
          end
        end

        def find_person(id)
          ::Operations::People::Find.new.call({person_id: id})
        end

        def find_profile(id)
          Success(::BenefitSponsors::Organizations::Profile.find(id))
        end

        def build_employer(profile_type)
          params_hash = { profile_type: profile_type,
                          staff_roles: [construct_staff_role_params],
                          organization: construct_organization_params }

          obj = JSON.parse(params_hash.to_json, object_class: OpenStruct)
          result = add_custom_methods_on_struct(obj)
          Success(result)
        end

        def construct_staff_role_params
          staff_role_hash = { person_id: @person&.id.to_s,
                              first_name: @person&.first_name,
                              last_name: @person&.last_name,
                              email: @person&.work_email_or_best,
                              dob: @person&.dob&.strftime("%m/%d/%Y"),
                              area_code: nil,
                              number: nil }
          staff_role_hash.merge!(coverage_record: construct_coverage_record)
          staff_role_hash
        end

        def construct_organization_params
          existing_org = @profile&.organization
          organization = BenefitSponsors::Entities::Organizations::Organization.to_hash(BenefitSponsors::Organizations::GeneralOrganization.new({entity_kind: existing_org&.entity_kind, legal_name: existing_org&.legal_name, dba: existing_org&.dba}))
          organization.merge!(profile: construct_profile_params)
        end

        def construct_profile_params
          profile = BenefitSponsors::Entities::Profiles::AcaShopDcEmployerProfile.to_hash(@profile || BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new)
          profile.merge!(office_locations: [construct_office_location]) if @profile.blank?
          profile
        end

        def construct_office_location
          BenefitSponsors::Entities::OfficeLocations::OfficeLocation.to_hash(BenefitSponsors::Locations::OfficeLocation.new(address: construct_address, phone: construct_phone))
        end

        def construct_address
          BenefitSponsors::Locations::Address.new
        end

        def construct_phone
          BenefitSponsors::Locations::Phone.new
        end

        def construct_coverage_record
          BenefitSponsors::Entities::Employers::EmployerStaffRoles::CoverageRecord.to_hash(build_coverage_record)
        end

        def build_coverage_record
          CoverageRecord.new(ssn: @person&.ssn,
                             gender: @person&.gender,
                             dob: @person&.dob&.strftime("%m/%d/%Y"),
                             hired_on: nil,
                             is_applying_coverage: false,
                             has_other_coverage: false,
                             is_owner: false,
                             address: build_address_for_coverage_record,
                             email: build_email_for_coverage_record)
        end

        def build_address_for_coverage_record
          home_address = @person&.home_address
          Address.new(kind: 'home',
                      address_1: home_address&.kind,
                      address_2: home_address&.address_2,
                      address_3: home_address&.address_3,
                      city: home_address&.city,
                      county: home_address&.county,
                      state: home_address&.state,
                      zip: home_address&.zip)
        end

        def build_email_for_coverage_record
          email = @person&.work_email || @person&.home_email
          Email.new(kind: email&.kind,
                    address: email&.address)
        end

        def add_custom_methods_on_struct(obj)
          obj[:staff_roles_attributes] = nil
          obj[:persisted?] = false
          obj.staff_roles.first[:persisted?] = false
          obj.organization.profile[:office_locations_attributes] = nil
          obj.organization.profile.office_locations.first[:persisted?] = false
          obj.organization.profile.contact_method_options = ::BenefitMarkets::CONTACT_METHODS_HASH
          obj.organization.profile.office_locations.each do |ol|
            ol.address.office_kind_options = BenefitSponsors::Locations::Address::OFFICE_KINDS
          end
          obj.organization.entity_kind_options = "BenefitSponsors::Organizations::Organization::ENTITY_KINDS".constantize
          obj
        end
      end
    end
  end
end