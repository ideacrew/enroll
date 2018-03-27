# Given a profile class, produce and persist appropriate combinations of associated models under the
# following steps:
#
# Get Site
# Initialize appropriate organization type, associate with Site, set legal_name and other attributes 
# from options (e.g. organization_agency, organization_office_location, organization_dba, organization_entity_kind)
# => GeneralOrganization if fein.present?
# => ExemptOrganization if fein.blank?
# => Initialize BenefitSponsorship with BenefitCatalog association
# Note following rules:
# => Only works if profile.is_benefit_sponsorship_eligible?
# => Only one HbxProfile may exist per Site
# => Only HbxProfile, FehbProfile (Congress), and EmployerProfile and subclasses are eligible for BenefitSponsorship


module BenefitSponsors
  module Organizations
    module Factories
      class BenefitSponsorFactory < OrganizationProfileFactory
        attr_accessor :email, :area_code, :number, :extension, :profile

        def initialize(profile, opts = {})
          @profile = profile
          super(opts)
        end

        def init_benefit_sponsor
          organization = init_organization
          profile.entity_kind = entity_kind
          profile.contact_method = contact_method

          organization.profiles << profile
          organization.save!
        end

        def save(current_user)
          return false unless valid?
          begin
            match_or_create_person(current_user)
            person.save!
            person.contact_info(email, area_code, number, extension) if email
          rescue TooManyMatchingPeople
            errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
            return false
          rescue PersonAlreadyMatched
            errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
            return false
          end
          return false if person.errors.present?
          existing_org, claimed = check_existing_organization
          if existing_org
            if existing_org.is_an_issuer_profile?
              errors.add(:base, "Issuer cannot sponsor benefits")
              return false
            end
            update_organization(existing_org) unless claimed
            @profile = existing_org.employer_profile
          else
            init_benefit_sponsor
          end
          pending = create_employer_staff_role(current_user, profile, claimed)
          [true, pending]
        end

        def check_existing_organization
          # for now we're always doing General Organization
          class_name = GeneralOrganization || ExemptOrganization 
          existing_org = class_name.where(:fein => fein).first
          if existing_org.present?
            if existing_org.employer_profile.present?
              if (Person.where({"employer_staff_roles.employer_profile_id" => existing_org.employer_profile._id}).any?)
                claimed = true
              end
            end
          end
          [existing_org, claimed]
        end

        def create_employer_staff_role(current_user, profile, existing_company)
          person.user = current_user
          employer_ids = person.employer_staff_roles.map(&:employer_profile_id)
          if employer_ids.include? profile.id
            pending = false
          else
            pending = existing_company && Person.staff_for_employer(profile).detect{|person|person.user_id}
            role_state = pending ? 'is_applicant' : 'is_active' 
            person.employer_staff_roles << EmployerStaffRole.new(person: person, :employer_profile_id => profile.id, is_owner: true, aasm_state: role_state)
          end
          current_user.roles << "employer_staff" unless current_user.roles.include?("employer_staff")
          current_user.save!
          person.save!
          pending
        end

        def update_organization(org)
          if !org.employer_profile.present?
            profile.entity_kind = entity_kind
            org.profiles << profile
            org.save!
          end
        end
      end
    end
  end
end
