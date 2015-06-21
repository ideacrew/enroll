module Forms
  class BrokerAgencyStaffRole < ::Forms::PersonSignup
    include ActiveModel::Validations

    attr_accessor :broker_agency_id
    
    def self.model_name
      ::BrokerAgencyStaffRole.model_name
    end

    def create_broker_agency_staff_role(current_user, broker_agency_profile)
      person.user = current_user
      person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new(:broker_agency_profile => broker_agency_profile)
      current_user.roles << "broker_agency_staff" unless current_user.roles.include?("broker_agency_staff")
      current_user.save!
    end

    def save(current_user)
      return false unless valid?
      begin
        match_or_create_person(current_user)
        create_new_user unless current_user
        person.save!
      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue PersonAlreadyMatched
        errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
        return false
      end

      broker_agency_profile = ::BrokerAgencyProfile.find(broker_agency_id)
      create_broker_agency_staff_role((current_user || person.user), broker_agency_profile)

      true
    end
  end
end