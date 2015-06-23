module Forms
  class BrokerRole < ::Forms::PersonSignup
    include ActiveModel::Validations

    attr_accessor :broker_agency_profile
    attr_accessor :npn, :broker_agency_id


    class BrokerNpnAlreadyExists < StandardError; end
    class BrokerAgencyMissing < StandardError; end

    def self.model_name
      ::BrokerRole.model_name
    end

    def create_broker_role(user, broker_agency_profile)
      person.broker_role = ::BrokerRole.new({ :provider_kind => 'broker', :npn => self.npn, :broker_agency_profile => broker_agency_profile })
      user.roles << "broker" unless user.roles.include?("broker")
      user.save!
    end

    def save(current_user)
      return false unless valid?
      begin
        match_broker_agency
        match_broker_npn
        match_or_create_person(current_user)
        create_new_user unless current_user
        person.save!
      rescue TooManyMatchingPeople
        errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX.")
        return false
      rescue PersonAlreadyMatched
        errors.add(:base, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
        return false
      rescue BrokerAgencyMissing
        errors.add(:base, "please select your broker agency.")
        return false
      rescue BrokerNpnAlreadyExists
        errors.add(:base, "provided NPN has already been claimed by another broker.  Please contact HBX.")
        return false
      end

      create_broker_role((current_user || person.user), broker_agency_profile)
      true
    end

    def match_broker_agency
      raise BrokerAgencyMissing.new if self.broker_agency_id.blank?
      self.broker_agency_profile = ::BrokerAgencyProfile.find(self.broker_agency_id)
    end

    def match_broker_npn
    end
  end
end
