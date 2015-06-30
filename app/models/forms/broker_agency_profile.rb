require 'date'
module Forms
  class BrokerAgencyProfile < ::Forms::OrganizationSignup
    attr_accessor :broker_agency_profile
    attr_accessor :market_kind, :languages_spoken
    attr_accessor :working_hours, :accept_new_clients, :home_page
    attr_accessor :broker_applicant_type, :email
    include NpnField

    validates :market_kind,
      inclusion: { in: ::BrokerAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid market kind" },
      allow_blank: false

    class OrganizationAlreadyMatched < StandardError; end

    def self.model_name
      ::BrokerAgencyProfile.model_name
    end

    def check_existing_organization
      fein_value = self.fein
      existing_org = Organization.where(:fein => fein_value).first
      if existing_org.present?
        raise OrganizationAlreadyMatched.new
      end
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
        match_or_create_person(current_user)
        person.add_work_email(email)
        person.save!
        add_broker_role

      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue PersonAlreadyMatched
        errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
        return false
      end

      begin
        check_existing_organization
      rescue OrganizationAlreadyMatched
        errors.add(:base, "organization has already been created.")
        return false
      end

      organization = create_new_organization
      self.broker_agency_profile = organization.broker_agency_profile
      self.broker_agency_profile.primary_broker_role = person.broker_role
      self.broker_agency_profile.save!

      true
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
          :languages_spoken => languages_spoken,
          :working_hours => working_hours,
          :accept_new_clients => accept_new_clients
        }),
        :office_locations => office_locations
      )
    end

  end
end
