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

    def create_broker_agency_staff_role(current_user, broker_agency_profile)
      person.user = current_user
      person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new(:broker_agency_profile => broker_agency_profile)
      current_user.roles << "broker_agency_staff" unless current_user.roles.include?("broker_agency_staff")
      current_user.save!
    end

    def create_broker_role(user, broker_agency_profile)
      person.broker_role = ::BrokerRole.new({ :provider_kind => 'broker', :npn => self.npn, :broker_agency_profile => broker_agency_profile })
      user.roles << "broker" unless user.roles.include?("broker")
      user.save!
    end

    def save(current_user)
      return false unless valid?
      begin
        match_or_create_person(current_user)
        person.add_work_email(email)
        person.save!
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
        errors.add(:base, "a staff role for this organization has already been claimed.")
        return false
      end
      organization = create_new_organization
      organization.save!
      self.broker_agency_profile = organization.broker_agency_profile
      if current_user
        create_broker_agency_staff_role(current_user, organization.broker_agency_profile)
      else
#        create_broker_agency_staff_role(person.user, organization.broker_agency_profile)
#        create_broker_role(person.user, organization.broker_agency_profile)
        self.broker_agency_profile.primary_broker_role = person.broker_role
        self.broker_agency_profile.save!
      end
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
