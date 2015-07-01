module Forms
  class BrokerAgencyStaffRole < ::Forms::PersonSignup
    include ActiveModel::Validations

    attr_accessor :broker_agency_id
    validate :broker_agency_presence
    
    def self.model_name
      ::BrokerAgencyStaffRole.model_name
    end

    def save
      return false unless valid?
      begin
        match_or_create_person
        person.save!
      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue PersonAlreadyMatched
        errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
        return false
      end

      broker_agency_profile = ::BrokerAgencyProfile.find(broker_agency_id)
      person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new(:broker_agency_profile => broker_agency_profile)
      
      true
    end

    def broker_agency_presence
      if self.broker_agency_id.blank? || ::BrokerAgencyProfile.find(self.broker_agency_id).blank?
        errors.add(:base, "please select your broker agency.")
      end
    end
  end
end