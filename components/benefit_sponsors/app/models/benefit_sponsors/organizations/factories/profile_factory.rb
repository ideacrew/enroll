require 'date'
module BenefitSponsors
  module Organizations
    module Factories
      class ProfileFactory
        include ActiveModel::Validations
        include BenefitSponsors::Forms::NpnField

        attr_accessor :profile_id, :profile_type, :organization, :current_user
        attr_accessor :first_name, :last_name, :email, :dob, :npn, :fein, :person, :market_kind

        validate :validate_duplicate_npn, if: :is_broker_profile?

        class PersonAlreadyMatched < StandardError; end
        class TooManyMatchingPeople < StandardError; end
        class OrganizationAlreadyMatched < StandardError; end

        def validate_duplicate_npn
          if Person.where("broker_role.npn" => npn).any?
            errors.add(:base, "NPN has already been claimed by another broker. Please contact HBX-Customer Service - Call (855) 532-5465.")
          end
        end

        def self.call_persist(current_user, attributes)
          factory_obj = new(attributes)
          factory_obj.current_user = current_user
          factory_obj.save(attributes)
        end

        def self.call_update(organization, attributes)
          organization.update_attributes(attributes)
        end

        def initialize(attrs)
          self.profile_type = attrs[:profile_type]
          self.first_name = attrs[:first_name]
          self.last_name = attrs[:last_name]
          self.email = attrs[:email]
          self.dob = attrs[:dob]
          self.npn = attrs[:npn]
          self.fein = attrs[:fein]
          self.profile_id = attrs[:id]
        end

        def self.initialize_parent(attrs)
          new(attrs).build_organization
        end

        def build_organization(attrs = {})
          if profile_id.blank?
            self.organization = build_organization_class.new(organization_attributes(attrs))
            self.organization.profiles << build_profile(profile_attributes(attrs))
            self.organization
          else
            get_organization
          end
        end

        def organization_attributes(attrs = {})
          attrs.except(:profiles_attributes).merge({
            site: site,
            fein: (fein.present? ? regex_for(fein): nil)
          })
        end

        def profile_attributes(attrs={})
          attrs["profiles_attributes"]["0"] if attrs["profiles_attributes"].present?
        end

        def get_organization
          build_organization_class.where(:"profiles._id" => BSON::ObjectId.from_string(profile_id)).first
        end

        def build_profile(attrs = {})
          profile = if is_broker_profile?
                      build_broker_profile(attrs)
                    elsif is_employer_profile?
                      build_sponsor_profile(attrs)
                    end
          profile.office_locations << build_office_locations if profile.office_locations.empty?
          profile
        end

        def build_office_locations
          new_office_location = Locations::OfficeLocation.new
          new_office_location.build_address
          new_office_location.build_phone
          new_office_location
        end

        def build_broker_profile(attrs = {})
          Organizations::BrokerAgencyProfile.new(attrs)
        end

        def build_sponsor_profile(attrs = {})
          build_sponsor_profile_class.new(attrs)
        end

        def build_sponsor_profile_class
          if site_key == :dc
            Organizations::AcaShopDcEmployerProfile
          elsif site_key == :cca
            Organizations::AcaShopCcaEmployerProfile
          end
        end

        def build_organization_class
          # Use GeneralOrganization for now
          GeneralOrganization || ExemptOrganization
        end

        def redirection_url(is_pending=nil, is_saved=nil)
          if is_broker_profile?
            :broker_new_registration_url
          elsif is_employer_profile?
            :sponsor_show_pending_registration_url if is_pending
            :sponsor_home_registration_url if is_saved
            :sponsor_new_registration_url
          end
        end

        def save(attributes)
          begin
            match_or_create_person(current_user)
            existing_org = check_existing_organization
          rescue TooManyMatchingPeople
            errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
            return false, redirection_url
          rescue PersonAlreadyMatched
            errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
            return false, redirection_url
          rescue OrganizationAlreadyMatched
            errors.add(:base, "Organization has already been created for this Agency type")
            return false, redirection_url
          end

          return false, redirection_url if check_validity(existing_org)

          if is_broker_profile?
            update_broker_agency_profile(existing_org, attributes)
          elsif is_employer_profile?
            claimed = is_employer_profile_claimed?(existing_org)
            update_employer_profile existing_org, claimed, attributes
            pending = create_employer_staff_role(current_user, existing_org.employer_profile, claimed)
          end
          [true, redirection_url(pending, true)]
        end

        def check_validity(org)
          issuer_requesting_sponsor_benefits?(org) || broker_profile_already_registered?(org) || person.errors.present?
        end 

        def update_broker_agency_profile(organization, attributes)
          add_broker_role
          # Building Organization as met criteria
          organization = init_broker_organization(organization, attributes["agency_organization"])
          profile = organization.broker_agency_profile
          profile.primary_broker_role = person.broker_role
          profile.save!
          update_broker_role(profile)
        end

        def init_broker_organization(organization, attributes)
          if organization.present? && !organization.broker_agency_profile.present?
            organization.profiles << build_profile(profile_attributes(attributes))
            organization
          else
            build_organization(attributes)
          end
        end

        def broker_profile_already_registered?(organization)
          if is_broker_profile?
            organization.present? && organization.broker_agency_profile.present?
          end
        end

        def update_employer_profile(existing_org, claimed, attributes)
          init_benefit_organization(existing_org).update_attributes!(attributes.merge({
            legal_name: regex_for(attributes[:legal_name]),
            fein: regex_for(attributes[:fein])
          }))
        end

        def init_benefit_organization(existing_org)
          if existing_org
            unless claimed
              if existing_org.employer_profile.blank?
                existing_org.profiles << build_profile
              end
            end
            existing_org
          else
            build_organization
          end
        end

        def issuer_requesting_sponsor_benefits?(organization)
          if organization.present? && organization.is_an_issuer_profile?
            errors.add(:base, "Issuer cannot sponsor benefits")
            return true
          end
        end

        def update_broker_role(broker_profile)
          person.broker_role.update_attributes({ broker_agency_profile_id: broker_profile.id , market_kind:  market_kind })
          ::UserMailer.broker_application_confirmation(person).deliver_now
        end

        def add_broker_role
          person.broker_role = ::BrokerRole.new({
            :provider_kind => 'broker',
            :npn => self.npn
          })
        end

        def init_organization
          # Use GeneralOrganization for now
          class_name = GeneralOrganization || ExemptOrganization 

          class_name.new(
            :site => site
          )
        end

        def site
          BenefitSponsors::ApplicationController::current_site
        end

        def site_key
          site.site_key
        end

        def is_broker_profile?
          profile_type == "broker_agency"
        end

        def is_employer_profile?
          profile_type == "benefit_sponsor"
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

        def match_or_create_person(current_user=nil)
          if is_employer_profile? || is_broker_profile?
            matched_people = Person.where(
              first_name: regex_for(first_name),
              last_name: regex_for(last_name),
              dob: dob
              )
          else
            matched_people = Person.where(
              first_name: regex_for(first_name),
              last_name: regex_for(last_name)
            )
          end

          if matched_people.count > 1
            raise TooManyMatchingPeople.new
          end

          if matched_people.count == 1
            mp = matched_people.first
            if is_employer_profile? && mp.user.present?
              if mp.user.id.to_s != current_user.id
                raise PersonAlreadyMatched.new
              end
            end
            self.person = mp
          else
            self.person = Person.new({
              :first_name => first_name,
              :last_name => last_name,
              :dob => dob
            })
          end

          if is_broker_profile?
            self.person.add_work_email(email)
            #TODO: Handling update Phones on Person using OL hash
            # @office_locations.each do  |office_location|
            #   self.person.phones.push(Phone.new(office_location.phone.attributes.except("_id")))
            # end
          elsif is_employer_profile?
            person.contact_info(email, area_code, number, extension) if email
          end
          person.save!
        end

        def is_employer_profile_claimed?(organization)
          if organization.present? && organization.employer_profile.present?
            if (Person.where({"employer_staff_roles.employer_profile_id" => organization.employer_profile._id}).any?)
              return true
            end
          elsif organization.broker_agency_profile.present?
            raise OrganizationAlreadyMatched.new
          end
        end

        def check_existing_organization
          Organization.where(:fein => fein).first
        end

        def regex_for(str)
          clean_string = Regexp.escape(str.strip)
          /^#{clean_string}$/i
        end
      end
    end
  end
end
