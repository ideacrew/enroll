require 'date'
module BenefitSponsors
  module Organizations
    module Factories
      class BrokerAgencyProfileFactory < OrganizationProfileFactory

        attr_accessor :broker_agency_profile

        def self.call(attrs)
          bap = new(attrs)
          result = bap.save_broker_profile
          return {is_saved: result, url: redirection_url, profile: bap.broker_agency_profile}
        end

        def self.redirection_url
          :broker_new_registration_url
        end

        def initialize(attrs)
          super(attrs)
        end

        def save_broker_profile
          begin
            match_or_create_person
            check_existing_organization
          rescue TooManyMatchingPeople
            errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
            return false
          rescue OrganizationAlreadyMatched
            errors.add(:base, "organization has already been created.")
            return false
          end
          person.save!
          add_broker_role
          organization = create_or_find_organization
          self.broker_agency_profile = organization.broker_agency_profile
          self.broker_agency_profile.primary_broker_role = person.broker_role
          self.broker_agency_profile.save!
          person.broker_role.update_attributes({ benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id , market_kind:  market_kind })
          ::UserMailer.broker_application_confirmation(person).deliver_now
          true
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

        # def self.model_name
        #   ::BrokerAgencyProfile.model_name
        # end

        def add_broker_role
          person.broker_role = ::BrokerRole.new({
            :provider_kind => 'broker',
            :npn => self.npn
          })
        end

        def match_or_create_person
          matched_people = Person.where(
            first_name: regex_for(first_name),
            last_name: regex_for(last_name),
            dob: dob
            )

          if matched_people.count > 1
            raise TooManyMatchingPeople.new
          end

          if matched_people.count == 1
            self.person = matched_people.first
          else
            self.person = Person.new({
              first_name: first_name,
              last_name: last_name,
              dob: dob
              })
          end

          self.person.add_work_email(email)
          # since we can have multiple office_locations each will have separate phone numbers
          @office_locations.each do  |office_location|
            self.person.phones.push(Phone.new(office_location.phone.attributes.except("_id")))
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

        def check_existing_organization
          existing_org = GeneralOrganization.where(:fein => self.fein).first
          if existing_org.present? && existing_org.broker_agency_profile.present?
            raise OrganizationAlreadyMatched.new
          end
        end
      end
    end
  end
end
