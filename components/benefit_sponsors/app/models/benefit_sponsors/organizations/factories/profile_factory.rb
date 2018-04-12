require 'date'
module BenefitSponsors
  module Organizations
    module Factories
      class ProfileFactory
        include ActiveModel::Validations
        include BenefitSponsors::Forms::ProfileInformation
        include BenefitSponsors::Forms::NpnField

        attr_reader :first_name, :last_name, :dob, :fein, :office_locations, :npn

        attr_accessor :legal_name, :dba, :entity_kind, :email, :person_id, :contact_method, :npn, :market_kind, 
                      :languages_spoken, :working_hours, :accept_new_clients, :person, :home_page

        attr_accessor :profile, :current_user

        validate :validate_duplicate_npn, if: :is_broker_profile?

        class PersonAlreadyMatched < StandardError; end
        class TooManyMatchingPeople < StandardError; end
        class OrganizationAlreadyMatched < StandardError; end

        def validate_duplicate_npn
          if Person.where("broker_role.npn" => npn).any?
            errors.add(:base, "NPN has already been claimed by another broker. Please contact HBX-Customer Service - Call (855) 532-5465.")
          end
        end

        def self.call(current_user, attrs)
          profile = new(attrs)
          profile.current_user = current_user
          if profile.valid?
            save_result, is_pending = profile.save
            return save_result, profile.redirection_url(save_result, is_pending)
          else
            return false, profile.redirection_url
          end
        end

        def redirection_url(is_saved=nil, is_pending=nil)
          if is_broker_profile?
            :broker_new_registration_url
          elsif is_employer_profile?
            :sponsor_show_pending_registration_url if is_pending
            :sponsor_home_registration_url if is_saved
            :sponsor_new_registration_url
          end
        end

        def initialize(attrs)
          @profile_type = attrs[:profile_type]
          self.fein = attrs[:fein]
          self.first_name = attrs[:first_name]
          self.last_name = attrs[:last_name]
          self.dob = attrs[:dob]
          self.legal_name = attrs[:legal_name]
          self.dba = attrs[:dba]
          self.entity_kind = attrs[:entity_kind]
          self.email = attrs[:email]
          self.contact_method = attrs[:contact_method]
          self.person_id = attrs[:person_id]
          self.npn = attrs[:npn]
          self.market_kind = attrs[:market_kind]
          self.home_page = attrs[:home_page]
          self.languages_spoken = attrs[:languages_spoken]
          self.working_hours = attrs[:working_hours]
          self.accept_new_clients = attrs[:accept_new_clients]
          self.office_locations_attributes = attrs[:office_locations_attributes]
        end

        def save
          begin
            match_or_create_person(current_user)
            existing_org, claimed =  check_existing_organization
          rescue TooManyMatchingPeople
            errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
            return false
          rescue PersonAlreadyMatched
            errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
            return false
          rescue OrganizationAlreadyMatched
            errors.add(:base, "Organization has already been created for this Agency type")
            return false
          end

          return false if person.errors.present?

          if is_broker_profile?
            update_broker_agency_profile
          elsif is_employer_profile?
            update_employer_profile existing_org, claimed
            pending = create_employer_staff_role(current_user, @sponsor_profile, claimed)
          end
          [true, pending]
        end

        def update_broker_agency_profile
          add_broker_role
          organization = create_or_find_organization
          self.profile = organization.broker_agency_profile
          self.profile.primary_broker_role = person.broker_role
          self.profile.save!
          update_broker_role
        end

        def update_employer_profile(existing_org, claimed)
          if existing_org
            if existing_org.is_an_issuer_profile?
              errors.add(:base, "Issuer cannot sponsor benefits")
              return false
            end
            update_organization(existing_org) unless claimed
            @sponsor_profile = existing_org.employer_profile
          else
            init_benefit_sponsor
          end
        end

        def update_broker_role
          person.broker_role.update_attributes({ broker_agency_profile_id: profile.id , market_kind:  market_kind })
          ::UserMailer.broker_application_confirmation(person).deliver_now
        end

        def add_broker_role
          person.broker_role = ::BrokerRole.new({
            :provider_kind => 'broker',
            :npn => self.npn
          })
        end

        def init_benefit_sponsor
          organization = init_organization
          class_name = init_profile_class
          update_organization(organization)
          organization
        end

        def init_organization
          # Use GeneralOrganization for now
          class_name = GeneralOrganization || ExemptOrganization 

          class_name.new(
            :fein => fein,
            :legal_name => legal_name,
            :dba => dba,
            :entity_kind => entity_kind,
            :site => site
          )
        end

        def site
          BenefitSponsors::ApplicationController::current_site
        end

        def update_organization(org)
          if !org.employer_profile.present?
            @sponsor_profile = class_name.new({
              :entity_kind => entity_kind,
              :contact_method => contact_method,
              :office_locations => office_locations
            })
            org.profiles << sponsor_profile
            org.save!
          end
        end

        def create_or_find_organization
          existing_org = GeneralOrganization.where(:fein => self.fein)
          if existing_org.present? && !existing_org.first.broker_agency_profile.present?
            new_broker_agency_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.new(
              entity_kind: entity_kind,
              market_kind: market_kind,
              corporate_npn: npn,
              home_page: home_page,
              languages_spoken: languages_spoken,
              working_hours: working_hours,
              accept_new_clients: accept_new_clients,
              office_locations: office_locations
            )
            existing_org = existing_org.first
            existing_org.profiles << new_broker_agency_profile
            existing_org.save!
            existing_org
          else
            initialize_broker_profile
          end
        end

        def initialize_broker_profile
          organization = init_organization
          profile = BenefitSponsors::Organizations::BrokerAgencyProfile.new(
            entity_kind: entity_kind,
            market_kind: :aca_shop,
            office_locations: office_locations,
            corporate_npn: npn,
            home_page: home_page,
            languages_spoken: languages_spoken,
            working_hours: working_hours,
            accept_new_clients: accept_new_clients
          )
          organization.profiles << profile
          organization.save!
          organization
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
            @office_locations.each do  |office_location|
              self.person.phones.push(Phone.new(office_location.phone.attributes.except("_id")))
            end
          elsif is_employer_profile?
            person.contact_info(email, area_code, number, extension) if email
          end
          person.save!
        end

        def check_existing_organization
          existing_org = Organization.where(:fein => fein).first
          if existing_org.present?
            if existing_org.employer_profile.present? && is_employer_profile?
              if (Person.where({"employer_staff_roles.employer_profile_id" => existing_org.employer_profile._id}).any?)
                claimed = true
              end
            elsif existing_org.broker_agency_profile.present? && is_broker_profile?
              raise OrganizationAlreadyMatched.new
            end
          end
          return [existing_org, claimed]
        end

        def regex_for(str)
          clean_string = Regexp.escape(str.strip)
          /^#{clean_string}$/i
        end

        def is_broker_profile?
          @profile_type == "broker_agency"
        end

        def is_employer_profile?
          @profile_type == "benefit_sponsor"
        end
      end
    end
  end
end
