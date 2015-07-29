require 'date'
module Forms
  class BrokerAgencyProfile < ::Forms::OrganizationSignup

    include ActiveModel::Validations
    include Validations::Email

    attr_accessor :broker_agency_profile
    attr_accessor :market_kind, :languages_spoken
    attr_accessor :working_hours, :accept_new_clients, :home_page, :corporate_npn
    attr_accessor :broker_applicant_type, :email
    include NpnField

    validates :market_kind,
      inclusion: { in: ::BrokerAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid market kind" },
      allow_blank: false

    validates :email, :email => true, :allow_blank => false

    class OrganizationAlreadyMatched < StandardError; end

    def self.model_name
      ::BrokerAgencyProfile.model_name
    end

    def add_broker_role
      person.broker_role = ::BrokerRole.new({ 
        :provider_kind => 'broker', 
        :npn => self.npn 
      })
    end

    def save(current_user=nil)
      return false unless valid?

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

      organization = create_new_organization
      self.broker_agency_profile = organization.broker_agency_profile
      self.broker_agency_profile.primary_broker_role = person.broker_role
      self.broker_agency_profile.save!
      person.broker_role.update_attributes({ broker_agency_profile_id: broker_agency_profile.id })
      true
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
    end

    def create_new_organization
      Organization.create!(
        :fein => fein,
        :legal_name => legal_name,
        :dba => dba,
        :broker_agency_profile => ::BrokerAgencyProfile.new({
          :entity_kind => entity_kind,
          :home_page => home_page,
          :market_kind => market_kind,
          :corporate_npn => corporate_npn,
          :languages_spoken => languages_spoken,
          :working_hours => working_hours,
          :accept_new_clients => accept_new_clients
        }),
        :office_locations => office_locations
      )
    end

    def check_existing_organization
      if Organization.where(:fein => self.fein).any?
        raise OrganizationAlreadyMatched.new
      end
    end
  end
end
